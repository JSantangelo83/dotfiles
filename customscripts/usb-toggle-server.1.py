#!/usr/bin/python3
import pyautogui as pa,socket,time,os
from pynput import mouse,keyboard
from threading import Thread

HOST = '192.168.1.43'
PORT = 8300
CONNECTED = False

conn = None
addr = None

def usbip_unbind_audio():
    print('Unbinding usbip Audio...')
    os.system('sudo /usr/bin/usbip unbind -b 1-8')

def usbip_unbind():
    print('Unbinding usbip devices...')
    os.system('sudo /usr/bin/usbip unbind -b 1-5')
    os.system('sudo /usr/bin/usbip unbind -b 1-6')
    os.system('sudo /usr/bin/xmodmap /home/$USER/.config/xremap')

def usbip_bind_audio(conn):
    print('Binding usbip Audio...')
    os.system('sudo /usr/bin/usbip bind -b 1-8')
    conn.send('aonnect'.encode())

def usbip_bind(conn):
    print('Binding usbip devices...')
    os.system('sudo /usr/bin/usbip bind -b 1-5')
    os.system('sudo /usr/bin/usbip bind -b 1-6')
    conn.send('connect'.encode())

def socket_thread():
    while True:
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
            s.bind((HOST, PORT))
            print(f'Listening on {HOST}:{PORT}')
            s.listen()
            global conn
            global addr
            conn, addr = s.accept()
            with conn:
                print(f'Connected with {addr}')
                global CONNECTED
                CONNECTED = True
                while True:
                    data = conn.recv(10)
                    if (not data) or data.decode() == 'disconnect' or data.decode() == 'aisconnect':
                        print(f'Disconnected from {addr}')
                        if((not not data) and (data.decode() == 'aisconnect')): usbip_unbind_audio()
                        if((not not data) and (data.decode() == 'disconnect')): usbip_unbind()
                        CONNECTED = False
                        break;

def on_release(key):
    global CONNECTED
    global conn
    global addr
        
    if CONNECTED:
        if key == keyboard.Key.pause: usbip_bind_audio(conn)        
        if key == keyboard.Key.scroll_lock: usbip_bind(conn)
    else:
        print('No se puede cambiar de teclado, no hay conexion')

Thread(target=socket_thread).start()
keyboard.Listener(on_release=on_release).start()
