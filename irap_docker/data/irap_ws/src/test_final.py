import socket
import json
import time

def talk_to_arduino(method):
    socket_path = "/var/run/arduino-router.sock"
    try:
        with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
            s.settimeout(3.0) # เพิ่มเวลาเป็น 3 วินาที
            s.connect(socket_path)
            
            # ลองใช้ Format ที่เรียบง่ายที่สุด
            payload = {
                "method": method,
                "id": 1
            }
            
            message = json.dumps(payload) + "\n"
            print(f"Sending: {message.strip()}")
            s.sendall(message.encode())
            
            # รอสักนิดให้ Buffer ทำงาน
            time.sleep(0.5)
            
            response = s.recv(4096)
            return response.decode()
    except Exception as e:
        return f"Error: {e}"

print("--- Try $/version ---")
print(talk_to_arduino("$/version"))

print("\n--- Try mon/connected ---")
print(talk_to_arduino("mon/connected"))
