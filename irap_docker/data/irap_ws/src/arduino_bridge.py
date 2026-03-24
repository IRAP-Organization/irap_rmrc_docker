import socket
import msgpack
import sys

SOCKET_PATH = "/var/run/arduino-router.sock"

# 1. รับค่าความเร็วจาก Command Line (ตัวอย่าง: python3 motor_test.py 0.5 0.8)
try:
    left_speed = float(sys.argv[1]) if len(sys.argv) > 1 else 0.0
    right_speed = float(sys.argv[2]) if len(sys.argv) > 2 else 0.0
except ValueError:
    print("Error: Please provide numbers for speed.")
    sys.exit(1)

print(f"Sending Motor Speeds -> Left: {left_speed}, Right: {right_speed}")

# 2. สร้าง MessagePack RPC Request
# สำคัญ: params ต้องส่งเป็น list [left_speed, right_speed]
request = [0, 1, "set_motor_speed", [left_speed, right_speed]]
packed_req = msgpack.packb(request)

# 3. ส่งข้อมูลผ่าน Unix Socket
try:
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as client:
        client.connect(SOCKET_PATH)
        client.sendall(packed_req)
        
        # รับ Response กลับมา
        response_data = client.recv(1024)
        if response_data:
            response = msgpack.unpackb(response_data)
            print(f"Router Response: {response}")
            
except Exception as e:
    print(f"Connection failed: {e}")
