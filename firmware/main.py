import network
import socket
import time
import json
from pimoroni_i2c import PimoroniI2C
from breakout_bme68x import BreakoutBME68X

# --- 1. ENTER YOUR WI-FI CREDENTIALS ---
SSID = "YOUR_WIFI_NAME"
PASSWORD = "YOUR_WIFI_PASSWORD"

# --- 2. INITIALIZE BME688 SENSOR ---
i2c = PimoroniI2C(sda=4, scl=5)
bme = BreakoutBME68X(i2c, address=0x77)

# --- 3. CONNECT TO WI-FI ---
wlan = network.WLAN(network.STA_IF)
wlan.active(True)
wlan.connect(SSID, PASSWORD)

print("Connecting to Wi-Fi", end="")
while not wlan.isconnected():
    print(".", end="")
    time.sleep(0.5)

ip_address = wlan.ifconfig()[0]
print(f"\nConnected! Pico W IP Address: {ip_address}")

# --- 4. START HTTP SERVER ---
addr = socket.getaddrinfo("0.0.0.0", 80)[0][-1]
server = socket.socket()
server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
server.bind(addr)
server.listen(1)

print(f"Serving live weather data at: http://{ip_address}/data")

while True:
    try:
        client, client_addr = server.accept()
        request = client.recv(1024)
        
        # Read fresh sensor data
        temperature, pressure, humidity, gas, status, _, _ = bme.read()
        
        payload = json.dumps({
            "temperature_c": round(temperature, 2),
            "humidity_pct": round(humidity, 2),
            "pressure_hpa": round(pressure / 100.0, 2),
            "gas_ohms": round(gas, 0)
        })
        
        # Send HTTP response with JSON body
        response = (
            "HTTP/1.1 200 OK\r\n"
            "Content-Type: application/json\r\n"
            "Connection: close\r\n\r\n"
            + payload
        )
        client.send(response.encode("utf-8"))
        client.close()
        
    except Exception as e:
        print("Request error:", e)