// Krops Fertilizer Spreader — ESP32-C3 Super Mini + 1-channel relay
//
// The iOS app sends an explicit JSON command over BLE; the relay runs for
// amount / rate_per_min minutes and switches off by itself.
//
// No extra libraries: BLE and Preferences come with "esp32 by Espressif Systems" 3.x.
// Board: ESP32C3 Dev Module, USB CDC On Boot: Enabled. See ../README.md.
//
// Serial Monitor (115200, Newline) commands for bench tests without the app:
//   spray 0.5     stop     status     rate 2.9     cal 30
//   or a JSON line, e.g. {"cmd":"spray","id":"t1","amount":0.5,"unit":"L"}

#include <Arduino.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <Preferences.h>
#include <cmath>
#include "driver/gpio.h"
#include "config.h"

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------
enum class Mode { Idle, Spraying, Calibrating };

static Mode mode = Mode::Idle;
static float ratePerMin = DEFAULT_RATE_PER_MIN;
static char activeId[41] = "";
static char lastId[41] = "";
static float targetAmount = 0;
static uint32_t startedAt = 0;
static uint32_t durationMs = 0;
static uint32_t lastStatusAt = 0;

static volatile bool clientConnected = false;
static volatile bool disconnectEvent = false;

static BLECharacteristic* statusCharacteristic = nullptr;
static Preferences prefs;
static String deviceName;

// BLE writes arrive on the Bluetooth task. They are queued and handled in loop()
// so that only loop() ever touches the relay and the state above.
static const size_t MAX_COMMAND_LENGTH = 200;
struct RawCommand {
  char text[MAX_COMMAND_LENGTH + 1];
};
static QueueHandle_t commandQueue = nullptr;

// ---------------------------------------------------------------------------
// Relay & LED
// ---------------------------------------------------------------------------
static const int RELAY_ON_LEVEL = RELAY_ACTIVE_LOW ? LOW : HIGH;
static const int RELAY_OFF_LEVEL = RELAY_ACTIVE_LOW ? HIGH : LOW;

static void relayOff() {
  if (RELAY_OFF_FLOATING) {
    pinMode(RELAY_PIN, INPUT);
    return;
  }
  // Preload the output latch before switching to output so the relay never blips on.
  gpio_set_level((gpio_num_t)RELAY_PIN, RELAY_OFF_LEVEL);
  pinMode(RELAY_PIN, OUTPUT);
  digitalWrite(RELAY_PIN, RELAY_OFF_LEVEL);
}

static void relayOn() {
  gpio_set_level((gpio_num_t)RELAY_PIN, RELAY_ON_LEVEL);
  pinMode(RELAY_PIN, OUTPUT);
  digitalWrite(RELAY_PIN, RELAY_ON_LEVEL);
}

static void led(bool on) {
  digitalWrite(LED_PIN, on ? LOW : HIGH);  // onboard LED is active-LOW
}

static void updateLed() {
  uint32_t now = millis();
  if (mode != Mode::Idle) {
    led((now / 100) % 2);           // fast blink: relay ON
  } else if (clientConnected) {
    led(true);                      // solid: phone connected
  } else {
    led((now / 1000) % 2);          // slow blink: waiting for the phone
  }
}

// ---------------------------------------------------------------------------
// Minimal JSON for the app's flat commands, e.g. {"cmd":"spray","amount":0.75}
// ---------------------------------------------------------------------------
static const char* jsonValue(const char* json, const char* key) {
  char pattern[24];
  snprintf(pattern, sizeof(pattern), "\"%s\"", key);
  const char* p = strstr(json, pattern);
  if (!p) return nullptr;
  p += strlen(pattern);
  while (*p == ' ') p++;
  if (*p != ':') return nullptr;
  p++;
  while (*p == ' ') p++;
  return p;
}

static bool jsonString(const char* json, const char* key, char* out, size_t size) {
  const char* p = jsonValue(json, key);
  if (!p || *p != '"') return false;
  p++;
  size_t n = 0;
  while (*p && *p != '"' && n + 1 < size) out[n++] = *p++;
  out[n] = '\0';
  return *p == '"';  // false when unterminated or too long
}

static bool jsonNumber(const char* json, const char* key, float* out) {
  const char* p = jsonValue(json, key);
  if (!p) return false;
  char* end = nullptr;
  float value = strtof(p, &end);
  if (end == p) return false;
  *out = value;
  return true;
}

static bool isSafeId(const char* id) {
  for (const char* p = id; *p; p++) {
    if (!isalnum((unsigned char)*p) && *p != '-' && *p != '_') return false;
  }
  return true;
}

// ---------------------------------------------------------------------------
// Status
// ---------------------------------------------------------------------------
static uint32_t elapsedMs() {
  uint32_t elapsed = (uint32_t)(millis() - startedAt);
  return elapsed > durationMs ? durationMs : elapsed;
}

static float amountFor(uint32_t elapsed) {
  return ratePerMin * (float)elapsed / 60000.0f;
}

static void publish(const char* json) {
  Serial.println(json);
  if (statusCharacteristic) {
    statusCharacteristic->setValue((uint8_t*)json, strlen(json));
    if (clientConnected) statusCharacteristic->notify();
  }
}

static void publishIdle() {
  char json[160];
  snprintf(json, sizeof(json),
           "{\"state\":\"idle\",\"rate_per_min\":%.3f,\"unit\":\"%s\",\"max_amount\":%.3f,\"fw\":\"%s\"}",
           ratePerMin, UNIT, MAX_AMOUNT, FW_VERSION);
  publish(json);
}

static void publishProgress() {
  char json[220];
  if (mode == Mode::Spraying) {
    snprintf(json, sizeof(json),
             "{\"state\":\"spraying\",\"id\":\"%s\",\"target\":%.3f,\"duration_ms\":%lu,"
             "\"elapsed_ms\":%lu,\"rate_per_min\":%.3f,\"unit\":\"%s\"}",
             activeId, targetAmount, (unsigned long)durationMs, (unsigned long)elapsedMs(),
             ratePerMin, UNIT);
  } else {
    snprintf(json, sizeof(json),
             "{\"state\":\"calibrating\",\"duration_ms\":%lu,\"elapsed_ms\":%lu,"
             "\"rate_per_min\":%.3f,\"unit\":\"%s\"}",
             (unsigned long)durationMs, (unsigned long)elapsedMs(), ratePerMin, UNIT);
  }
  lastStatusAt = millis();
  publish(json);
}

static void publishError(const char* code, const char* id) {
  char json[120];
  if (id && *id && isSafeId(id)) {
    snprintf(json, sizeof(json), "{\"state\":\"error\",\"code\":\"%s\",\"id\":\"%s\"}", code, id);
  } else {
    snprintf(json, sizeof(json), "{\"state\":\"error\",\"code\":\"%s\"}", code);
  }
  publish(json);
}

// ---------------------------------------------------------------------------
// Commands
// ---------------------------------------------------------------------------
static void finish(const char* state, const char* reason) {
  relayOff();
  uint32_t elapsed = elapsedMs();
  bool calibrating = mode == Mode::Calibrating;
  mode = Mode::Idle;

  char json[220];
  int n = snprintf(json, sizeof(json), "{\"state\":\"%s\",", state);  // "done" or "stopped"
  if (calibrating) {
    n += snprintf(json + n, sizeof(json) - n, "\"mode\":\"calibrate\",");
  } else {
    n += snprintf(json + n, sizeof(json) - n, "\"id\":\"%s\",\"target\":%.3f,", activeId, targetAmount);
  }
  n += snprintf(json + n, sizeof(json) - n, "\"elapsed_ms\":%lu,\"amount_est\":%.3f,\"unit\":\"%s\"",
                (unsigned long)elapsed, amountFor(elapsed), UNIT);
  if (reason) n += snprintf(json + n, sizeof(json) - n, ",\"reason\":\"%s\"", reason);
  snprintf(json + n, sizeof(json) - n, "}");
  publish(json);
  activeId[0] = '\0';
}

static void startSpray(const char* id, float amount, const char* unit) {
  if (mode != Mode::Idle) return publishError("BUSY", id);
  if (!*id) return publishError("MISSING_ID", nullptr);
  if (strlen(id) >= sizeof(activeId) || !isSafeId(id)) return publishError("BAD_ID", nullptr);
  if (strcmp(lastId, id) == 0) return publishError("DUPLICATE_ID", id);
  if (strcasecmp(unit, UNIT) != 0) return publishError("UNIT_MISMATCH", id);
  if (!std::isfinite(amount) || amount <= 0) return publishError("BAD_AMOUNT", id);
  if (amount > MAX_AMOUNT) return publishError("OVER_LIMIT", id);
  if (!(ratePerMin > 0)) return publishError("NO_CALIBRATION", id);

  float duration = amount / ratePerMin * 60000.0f;
  if (duration > (float)MAX_DURATION_MS) return publishError("OVER_LIMIT", id);

  strncpy(lastId, id, sizeof(lastId) - 1);
  strncpy(activeId, id, sizeof(activeId) - 1);
  targetAmount = amount;
  durationMs = (uint32_t)lroundf(duration);
  startedAt = millis();
  mode = Mode::Spraying;
  relayOn();
  publishProgress();
}

static void startCalibration(int seconds) {
  if (mode != Mode::Idle) return publishError("BUSY", nullptr);
  if (seconds < MIN_CALIBRATION_S || seconds > MAX_CALIBRATION_S) return publishError("BAD_SECONDS", nullptr);
  targetAmount = 0;
  durationMs = (uint32_t)seconds * 1000UL;
  startedAt = millis();
  mode = Mode::Calibrating;
  relayOn();
  publishProgress();
}

static void setRate(float rate, const char* unit) {
  if (mode != Mode::Idle) return publishError("BUSY", nullptr);
  if (strcasecmp(unit, UNIT) != 0) return publishError("UNIT_MISMATCH", nullptr);
  if (!std::isfinite(rate) || rate < 0.1f || rate > 30.0f) return publishError("BAD_RATE", nullptr);
  ratePerMin = rate;
  prefs.putFloat("rate", rate);
  publishIdle();
}

static void stopActive(const char* reason) {
  if (mode == Mode::Idle) {
    relayOff();  // STOP is always safe to repeat
    publishIdle();
    return;
  }
  finish("stopped", reason);
}

static void handleCommand(const char* json) {
  char cmd[16];
  if (json[0] != '{' || !jsonString(json, "cmd", cmd, sizeof(cmd))) return publishError("BAD_JSON", nullptr);

  char unit[8] = UNIT;
  jsonString(json, "unit", unit, sizeof(unit));  // optional, defaults to UNIT

  if (strcmp(cmd, "spray") == 0) {
    char id[48] = "";
    float amount = -1;
    jsonString(json, "id", id, sizeof(id));
    jsonNumber(json, "amount", &amount);
    startSpray(id, amount, unit);
  } else if (strcmp(cmd, "stop") == 0) {
    stopActive("app");
  } else if (strcmp(cmd, "calibrate") == 0) {
    float seconds = 0;
    jsonNumber(json, "seconds", &seconds);
    startCalibration((int)seconds);
  } else if (strcmp(cmd, "set_rate") == 0) {
    float rate = -1;
    jsonNumber(json, "rate_per_min", &rate);
    setRate(rate, unit);
  } else if (strcmp(cmd, "ping") == 0) {
    if (mode == Mode::Idle) publishIdle(); else publishProgress();
  } else {
    publishError("UNKNOWN_CMD", nullptr);
  }
}

// Plain-text commands for the Serial Monitor.
static void handleSerialLine(String line) {
  line.trim();
  if (line.isEmpty()) return;
  if (line.startsWith("{")) return handleCommand(line.c_str());

  int space = line.indexOf(' ');
  String word = space < 0 ? line : line.substring(0, space);
  String arg = space < 0 ? "" : line.substring(space + 1);
  word.toLowerCase();

  if (word == "spray") {
    String id = "serial-" + String(millis());
    startSpray(id.c_str(), arg.toFloat(), UNIT);
  } else if (word == "stop") {
    stopActive("serial");
  } else if (word == "status") {
    if (mode == Mode::Idle) publishIdle(); else publishProgress();
  } else if (word == "rate") {
    setRate(arg.toFloat(), UNIT);
  } else if (word == "cal") {
    startCalibration(arg.toInt());
  } else {
    Serial.println("Perintah: spray <liter> | stop | status | rate <L/menit> | cal <detik>");
  }
}

static void readSerial() {
  static String line;
  while (Serial.available()) {
    char c = (char)Serial.read();
    if (c == '\n' || c == '\r') {
      handleSerialLine(line);
      line = "";
    } else if (line.length() < MAX_COMMAND_LENGTH) {
      line += c;
    }
  }
}

// ---------------------------------------------------------------------------
// BLE (library bawaan paket ESP32)
// ---------------------------------------------------------------------------
class ServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer* server) override {
    clientConnected = true;
  }

  void onDisconnect(BLEServer* server) override {
    clientConnected = false;
    disconnectEvent = true;
    BLEDevice::startAdvertising();  // let the phone reconnect
  }
};

class CommandCallbacks : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic* characteristic) override {
    String value = characteristic->getValue();
    RawCommand raw;
    size_t length = value.length();
    if (length > MAX_COMMAND_LENGTH) length = 0;  // oversized → empty → BAD_JSON
    memcpy(raw.text, value.c_str(), length);
    raw.text[length] = '\0';
    xQueueSend(commandQueue, &raw, 0);
  }
};

static void setupBLE() {
  uint64_t mac = ESP.getEfuseMac();
  char suffix[5];
  snprintf(suffix, sizeof(suffix), "%04X", (unsigned)((mac >> 32) & 0xFFFF));
  deviceName = String(DEVICE_NAME_PREFIX) + suffix;

  BLEDevice::init(deviceName.c_str());
  BLEDevice::setMTU(185);

  BLEServer* server = BLEDevice::createServer();
  server->setCallbacks(new ServerCallbacks());

  BLEService* service = server->createService(SERVICE_UUID);
  BLECharacteristic* command =
      service->createCharacteristic(COMMAND_UUID, BLECharacteristic::PROPERTY_WRITE);
  command->setCallbacks(new CommandCallbacks());
  statusCharacteristic = service->createCharacteristic(
      STATUS_UUID, BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY);
  statusCharacteristic->addDescriptor(new BLE2902());  // lets iOS subscribe to notifications
  service->start();

  // iOS scans by the service UUID; the name goes into the scan response.
  BLEAdvertising* advertising = BLEDevice::getAdvertising();
  advertising->addServiceUUID(SERVICE_UUID);
  advertising->setScanResponse(true);
  BLEDevice::startAdvertising();
}

// ---------------------------------------------------------------------------
// Emergency stop button (BOOT, GPIO9)
// ---------------------------------------------------------------------------
static void checkStopButton() {
  static uint32_t pressedSince = 0;
  if (digitalRead(STOP_BUTTON_PIN) == LOW) {
    if (pressedSince == 0) pressedSince = millis();
    if (mode != Mode::Idle && millis() - pressedSince > 30) stopActive("button");
  } else {
    pressedSince = 0;
  }
}

// ---------------------------------------------------------------------------
// Arduino
// ---------------------------------------------------------------------------
void setup() {
  relayOff();  // first thing: make sure the pump is off
  pinMode(LED_PIN, OUTPUT);
  led(false);
  pinMode(STOP_BUTTON_PIN, INPUT_PULLUP);

  Serial.begin(115200);
  delay(300);

  prefs.begin("spreader", false);
  ratePerMin = prefs.getFloat("rate", DEFAULT_RATE_PER_MIN);

  commandQueue = xQueueCreate(4, sizeof(RawCommand));
  setupBLE();
  enableLoopWDT();  // restart if loop() ever hangs; the relay is OFF after restart

  Serial.printf("Krops spreader %s siap sebagai %s, debit %.3f %s/menit\n",
                FW_VERSION, deviceName.c_str(), ratePerMin, UNIT);
  publishIdle();
}

void loop() {
  RawCommand raw;
  while (xQueueReceive(commandQueue, &raw, 0) == pdTRUE) {
    handleCommand(raw.text);
  }
  readSerial();
  checkStopButton();

  if (disconnectEvent) {
    disconnectEvent = false;
    if (!CONTINUE_ON_DISCONNECT && mode != Mode::Idle) stopActive("disconnect");
  }

  if (mode != Mode::Idle) {
    if ((uint32_t)(millis() - startedAt) >= durationMs) {
      finish("done", nullptr);
    } else if (millis() - lastStatusAt >= STATUS_INTERVAL_MS) {
      publishProgress();
    }
  }

  updateLed();
  delay(5);
}
