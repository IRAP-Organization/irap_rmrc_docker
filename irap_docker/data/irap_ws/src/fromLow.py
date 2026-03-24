import socket
import msgpack
import time

SOCKET_PATH = "/var/run/arduino-router.sock"

sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
sock.connect(SOCKET_PATH)

sock.setblocking(False)

unpacker = msgpack.Unpacker(raw=False)

# register method
register_msg = [0, 1, "$/register", ["motor_update"]]
sock.sendall(msgpack.packb(register_msg))

msgid = 10
i = 1
last_send = time.time()

while True:

    # ----- รับข้อมูลจาก Arduino -----
    try:
        data = sock.recv(4096)
        if data:
            unpacker.feed(data)

            for msg in unpacker:
                if msg[0] == 2:  # notification
                    method = msg[1]
                    params = msg[2]

                    if method == "motor_update":
                        left, right = params
                        print("Arduino motor:", left, right)

    except BlockingIOError:
        pass

    # ----- ส่งข้อมูลไป Arduino -----
    now = time.time()
    if now - last_send > 0.2 and i <= 100:

        left_speed = float(i)
        right_speed = float(i + 0.5)

        msg = [0, msgid, "set_motor_speed", [left_speed, right_speed]]
        sock.sendall(msgpack.packb(msg))

        print("Send:", left_speed, right_speed)

        msgid += 1
        i += 1
        last_send = now
