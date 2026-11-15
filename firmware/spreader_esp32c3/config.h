#pragma once

// ---------------------------------------------------------------------------
// Krops Fertilizer Spreader — ESP32-C3 Super Mini
// Keep the UUIDs in sync with PalmOilFarmer/Experiments/FertilizerSpreader/SpreaderProtocol.swift
// Copy the relay settings that worked in relay_blink into this file.
// ---------------------------------------------------------------------------

#define FW_VERSION "0.1.0"

// ---- Pins ------------------------------------------------------------------
#define RELAY_PIN 3         // Relay module IN (ESP 5V → DC+, GND → DC-, GPIO3 → IN)
#define LED_PIN 8           // Onboard LED, active-LOW
#define STOP_BUTTON_PIN 9   // Onboard BOOT button, active-LOW (emergency stop)

// ---- Relay drive -----------------------------------------------------------
// Most 5V optocoupler relay modules switch ON when IN is pulled LOW.
// If your module has a HIGH/LOW trigger jumper set to HIGH, change this to false.
#define RELAY_ACTIVE_LOW true

// ESP32-C3 drives 3.3V. Some 5V modules do not release with 3.3V on IN.
// If the relay stays ON in relay_blink, set this to true: OFF then releases the pin
// (high impedance) instead of driving 3.3V.
#define RELAY_OFF_FLOATING false

// ---- Dosing ----------------------------------------------------------------
#define UNIT "L"
#define DEFAULT_RATE_PER_MIN 2.9f   // L/min, measured for the current pump
#define MAX_AMOUNT 5.0f             // L per command
#define MAX_DURATION_MS 180000UL    // hard cap: 3 minutes relay ON
#define MIN_CALIBRATION_S 5
#define MAX_CALIBRATION_S 120
#define STATUS_INTERVAL_MS 500UL    // progress notifications while spraying

// Keep spraying until the timer ends if the phone disconnects mid-spray.
// The dose stays complete and the timer still bounds it. Set false to stop instead.
#define CONTINUE_ON_DISCONNECT true

// ---- BLE -------------------------------------------------------------------
#define DEVICE_NAME_PREFIX "KROPS-SPR-"
#define SERVICE_UUID "4b470001-2bfb-437b-a832-bdc71afca4e2"
#define COMMAND_UUID "4b470002-2bfb-437b-a832-bdc71afca4e2"   // Write: JSON command
#define STATUS_UUID  "4b470003-2bfb-437b-a832-bdc71afca4e2"   // Read + Notify: JSON status
