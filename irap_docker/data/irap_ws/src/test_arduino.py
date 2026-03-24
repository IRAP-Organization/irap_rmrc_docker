import socket
import json
import time

def send_rpc(method, params=None):
    socket_path = "/var/run/arduino-router.sock"
    try:
        with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
            s.settimeout(1.5)
            s.connect(socket_path)
            
            # โครงสร้าง JSON-RPC 2.0 ที่สมบูรณ์
            payload = {
                "jsonrpc": "2.0",
                "method": method,
                "params": params if params is not None else {},
                "id": 1
            }
            
            # ลองส่งแบบ \n และ \r\n พร้อมกันเพื่อความชัวร์
            message = json.dumps(payload) + "\n"
            s.sendall(message.encode())
            
            response = s.recv(4096)
            return response.decode()
    except socket.timeout:
        return "Error: Timeout - Service is not responding"
    except Exception as e:
        return f"Error: {e}"

print("--- Testing Arduino Router (Full RPC) ---")
# ลอง Method พื้นฐาน
print(f"1. Version Status: {send_rpc('$/version')}")
print(f"2. Connection Status: {send_rpc('mon/connected')}")
