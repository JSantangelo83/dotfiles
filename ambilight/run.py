#!/usr/bin/env python3
import socket
import json
import time
import threading

HYPERION_IP = "127.0.0.1"
WLED_IP = "192.168.100.229"
PORT_JSON = 19444
PORT_UDP = 19446

INSTANCES = [0, 1]
FADE_STEPS = 10
TARGET_FPS = 50  # frames per second
FRAME_TIME = 1.0 / TARGET_FPS

led_data = {i: None for i in INSTANCES}
lock = threading.Lock()
new_data_event = threading.Event()
running = True

udp = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)


def interpolate(prev, curr, t):
    return [int(p + (c - p) * t) for p, c in zip(prev, curr)]


def hyperion_listener(instance_id):
    """Listen to one Hyperion instance and auto-reconnect on failure."""
    global running

    while running:
        try:
            print(f"[Instance {instance_id}] Connecting to Hyperion...")
            sock = socket.create_connection((HYPERION_IP, PORT_JSON))
            msg = {
                "command": "ledcolors",
                "subcommand": "ledstream-start",
                "instance": instance_id
            }
            sock.sendall((json.dumps(msg) + "\n").encode())
            print(f"[Instance {instance_id}] Connected.")

            while running:
                data = sock.recv(65535)
                if not data:
                    raise ConnectionError("Connection closed by Hyperion")

                try:
                    msg = json.loads(data.decode(errors="ignore"))
                    leds = msg.get("data", {}).get("leds")
                    if leds:
                        with lock:
                            led_data[instance_id] = leds
                            if all(led_data.values()):
                                new_data_event.set()
                except json.JSONDecodeError:
                    continue

        except Exception as e:
            print(f"[Instance {instance_id}] Disconnected: {e}")
            if not running:
                break
            # exponential backoff reconnect
            delay = 1
            for _ in range(5):
                if not running:
                    break
                print(f"[Instance {instance_id}] Reconnecting in {delay}s...")
                time.sleep(delay)
                try:
                    sock.close()
                except:
                    pass
                delay = min(delay * 2, 30)
                break  # try reconnect immediately after delay
        finally:
            try:
                sock.close()
            except:
                pass


def main():
    global running
    prev_frame = None
    last_send_time = 0.0

    threads = [
        threading.Thread(target=hyperion_listener, args=(i,), daemon=True)
        for i in INSTANCES
    ]
    for t in threads:
        t.start()

    print(f"Streaming both Hyperion instances to WLED @ {TARGET_FPS} FPS...")

    while running:
        # Wait until both have data
        new_data_event.wait(timeout=1)
        new_data_event.clear()

        with lock:
            if not all(led_data.values()):
                continue
            merged = sum(led_data.values(), [])  # concat all frames

        if prev_frame is None:
            prev_frame = merged

        # Smooth transition using interpolation
        for step in range(1, FADE_STEPS + 1):
            t = step / FADE_STEPS
            fade_frame = interpolate(prev_frame, merged, t)
            header = bytes([0x02, 0x01, 0x00])
            payload = header + bytes(fade_frame)
            udp.sendto(payload, (WLED_IP, PORT_UDP))

            # FPS limiter
            now = time.perf_counter()
            elapsed = now - last_send_time
            if elapsed < FRAME_TIME:
                time.sleep(FRAME_TIME - elapsed)
            last_send_time = time.perf_counter()

        prev_frame = merged

    print("Stopping...")
    for t in threads:
        t.join()


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        running = False
        new_data_event.set()
        print("\nExiting cleanly.")
