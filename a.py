import bluetooth
import time

target_name = "BT SZM" 
target_address = None

print("Scanning devices...")
nearby_devices = bluetooth.discover_devices(duration=8, lookup_names=True)

for addr, name in nearby_devices:
    if target_name == name:
        target_address = addr
        break

if target_address is not None:
    print(f"Device found: {target_name} at {target_address}")
else:
    print("Device tidak ditemukan")

import subprocess

def quick_pair(address):
    try:
        subprocess.run(["bluetoothctl", "pair", address], check=True)
        subprocess.run(["bluetoothctl", "connect", address], check=True)
        print("Berhasil connect!")
    except subprocess.CalledProcessError:
        print("Gagal connect, try again...")

while True:
    quick_pair(target_address)
    time.sleep(0.5)
