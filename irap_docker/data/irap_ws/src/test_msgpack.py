import socket
import msgpack

def call_arduino(method, params=[]):
    socket_path = "/var/run/arduino-router.sock"
    try:
        with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
            s.settimeout(2.0)
            s.connect(socket_path)
            
            # MessagePack-RPC Format: [type, msgid, method, params]
            # 0 = Request
            payload = [0, 1, method, params]
            
            # Encode เป็น binary
            packed_data = msgpack.packb(payload)
            s.sendall(packed_data)
            
            # รับข้อมูล
            response_data = s.recv(4096)
            if response_data:
                # Decode ข้อมูลที่ได้รับ
                unpacked_response = msgpack.unpackb(response_data)
                print(f"Method: {method} -> Response: {unpacked_response}")
            else:
                print(f"Method: {method} -> No data received")
                
    except Exception as e:
        print(f"Method: {method} -> Error: {e}")

print("--- Testing Arduino Router with MessagePack ---")
print("--- Reading from Arduino ---")
# ลองอ่าน 64 bytes
call_arduino("mon/read", [64]) 

print("\n--- Testing Version again ---")
# บางครั้ง $/version ไม่ต้องการ params เลย (ส่งเป็น array ว่าง)
call_arduino("$/version", [])
