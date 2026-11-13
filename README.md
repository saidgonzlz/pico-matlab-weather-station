# Wireless IoT Weather Station & Micro-Climate Forecaster (Pico W + MATLAB)

A real-time wireless environmental telemetry, digital filtering, and short-term temperature forecasting system built with a **Raspberry Pi Pico W**, a **Pimoroni Enviro Indoor (BME688)** sensor board, and **MATLAB**.

![MATLAB Real-Time Plots](images/matlab_dashboard.png)

## How It Works
1. **Wireless Edge Server (MicroPython):** The Raspberry Pi Pico W reads temperature, relative humidity, barometric pressure, and VOC gas resistance from the BME688 sensor over I2C and hosts a lightweight HTTP JSON REST endpoint (`/data`) over local Wi-Fi.
2. **Data Acquisition & Signal Processing (MATLAB):** A MATLAB script polls the Pico W endpoint (`webread`), applies a moving-average digital filter (`movmean`) to smooth sensor quantization noise, and computes an online linear regression (`polyfit`) to forecast temperature trends 30 seconds ahead.
3. **Automated Data Logging:** Automatically exports all raw and filtered session telemetry to a structured CSV file (`weather_session_log.csv`) when the live plot window is closed.

## Hardware & Software Stack
* **Microcontroller:** Raspberry Pi Pico W (RP2040)
* **Sensor Shield:** Pimoroni Enviro Indoor (Bosch BME688 sensor)
* **Embedded Firmware:** Pimoroni Custom MicroPython (`network`, `socket`, `breakout_bme68x`)
* **Analytics & Visualization:** MATLAB (`webread`, `movmean`, `polyfit`, `polyval`)

![Hardware Setup](images/hardware_setup.jpg)

## Quick Start
1. Flash Pimoroni's custom MicroPython firmware onto your Raspberry Pi Pico W.
2. Add your Wi-Fi SSID and password in `firmware/main.py`, save it to the Pico W, and note the IP address printed in the shell.
3. Open `matlab/live_weather_forecaster.m` in MATLAB, update `pico_ip` on line 5 with your Pico's IP address, and click **Run**.
4. Close the figure window at any time to stop recording and export `weather_session_log.csv`.