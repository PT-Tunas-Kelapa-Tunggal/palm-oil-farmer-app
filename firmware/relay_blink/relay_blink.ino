// Phase 1 bench test: relay ON 2 s, OFF 2 s. No pump attached yet.
// Listen for a clean click on every change and watch the module's LED.
//
// If the relay stays ON while Serial says "OFF", try in this order:
//   1. Module with a HIGH/LOW trigger jumper: set it to LOW and keep ACTIVE_LOW true.
//   2. Set OFF_FLOATING true (OFF releases the pin instead of driving 3.3V).
//   3. Module with a JD-VCC jumper: remove it, VCC ← 3V3, JD-VCC ← 5V.
// Copy the settings that work into spreader_esp32c3/config.h.

#include "driver/gpio.h"

const int RELAY_PIN = 3;  // ESP 5V → DC+, GND → DC-, GPIO3 → IN
const bool ACTIVE_LOW = true;
const bool OFF_FLOATING = false;

const int ON_LEVEL = ACTIVE_LOW ? LOW : HIGH;
const int OFF_LEVEL = ACTIVE_LOW ? HIGH : LOW;

void relayOff() {
  if (OFF_FLOATING) {
    pinMode(RELAY_PIN, INPUT);
    return;
  }
  gpio_set_level((gpio_num_t)RELAY_PIN, OFF_LEVEL);
  pinMode(RELAY_PIN, OUTPUT);
  digitalWrite(RELAY_PIN, OFF_LEVEL);
}

void relayOn() {
  gpio_set_level((gpio_num_t)RELAY_PIN, ON_LEVEL);
  pinMode(RELAY_PIN, OUTPUT);
  digitalWrite(RELAY_PIN, ON_LEVEL);
}

void setup() {
  relayOff();
  Serial.begin(115200);
  delay(500);
  Serial.println("relay_blink: GPIO3, 2 detik ON / 2 detik OFF");
}

void loop() {
  relayOn();
  Serial.println("ON");
  delay(2000);
  relayOff();
  Serial.println("OFF");
  delay(2000);
}
