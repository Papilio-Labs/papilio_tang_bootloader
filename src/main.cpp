/**
 * Papilio RetroCade - Bootloader Hold Example
 * This will hold the FPGA in bootloader mode by keeping the BOOTLOADER_HOLD pin low. (This actually holds the FPGA in reset state.)
 */

#include <Arduino.h>

// Pin definitions
#define BOOTLOADER_HOLD 10    // GPIO pin connected to FPGA (maps to A9 - ESP32_GPIO1)

void setup() {
  pinMode(BOOTLOADER_HOLD, OUTPUT);
  digitalWrite(BOOTLOADER_HOLD, LOW);
  Serial.begin(115200);
  Serial.println("Starting");
}

void loop() {
  // BOOTLOADER_HOLD stays low
  Serial.println("Loop");
  delay(2000);
}
