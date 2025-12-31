#!/usr/bin/env python3
import argparse
import threading
import time
from datetime import datetime
import sys
import subprocess
import re
import json
import socket
from concurrent.futures import ThreadPoolExecutor

# Intentar importar tqdm
try:
    from tqdm import tqdm
except ImportError:
    print("\n[!] Error: La librería 'tqdm' no está instalada.")
    print("[*] Ejecuta: sudo pip3 install tqdm --break-system-packages\n")
    sys.exit(1)

# --- Configuración de Colores ---
class Colores:
    CYAN = '\033[96m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'

# --- Diccionario de Servicios ---
SERVICIOS_COMUNES = {
    21: "FTP", 22: "SSH", 23: "Telnet", 25: "SMTP", 53: "DNS",
    80: "HTTP", 110: "POP3", 111: "RPCBind", 135: "MSRPC",
    139: "NetBIOS", 143: "IMAP", 443: "HTTPS", 445: "SMB/MS-DS",
    3000: "NodeJS/React", 3003: "Dev-Micro", 3005: "Dev-Micro", 3006: "Dev-Micro",
    3306: "MySQL", 3389: "RDP", 5000: "Flask/Docker", 
    5331: "Backup-Svc", 5432: "PostgreSQL", 5900: "VNC", 
    6379: "Redis", 8080: "HTTP-Proxy", 8082: "HTTP-Alt/Proxy",
    4444: "Metasploit", 60000: "Deep-Backdoor"
}

def print_banner():
    # Banner actualizado a v2.2
    banner = r"""
     _ ___  _  __ _  ___  ___  __  __ _  __ _  ____ ___ 
  | |/ _ \| |/ /| |/ __|/ __|/ _\|  \| ||  \| ||  __| _ \
__| |  _  |   < | |\__ \ (__| (_ | .  || .  ||  __|   / 
\__/ \__| |_|\_\_|\____|\___|\__/|_|\_||_|\_||____|_|_/
                                v2.2 - Speed Profiles
    """   
    print(f"{Colores.CYAN}{banner}{Colores.ENDC}")

def detect_os(ip):
    try:
        process = subprocess.Popen(['ping', '-c', '1', '-W', '1', ip], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        out, _ = process.communicate()
        ttl_match = re.search(r"ttl=(\d+)", out.decode())
        if ttl_match:
            ttl = int(ttl_match.group(1))
            if ttl <= 64: return "Linux/Unix", ttl
            elif ttl <= 128: return "Windows", ttl
            else: return "Cisco/Network", ttl
    except: pass
    return "Desconocido", "N/A"

print_lock = threading.Semaphore(value=1)
results = []

def scan_port(target_ip, puerto, pbar, timeout_val):
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(timeout_val)
        result = sock.connect_ex((target_ip, puerto))
        if result == 0:
            nombre = SERVICIOS_COMUNES.get(puerto, "Desconocido")
            with print_lock:
                pbar.write(f"  [{Colores.GREEN}+{Colores.ENDC}] Puerto {Colores.BOLD}{puerto:<5}{Colores.ENDC} ({Colores.CYAN}{nombre:<12}{Colores.ENDC}) -> {Colores.GREEN}ABIERTO{Colores.ENDC}")
                results.append({"puerto": puerto, "servicio": nombre})
        sock.close()
    except: pass
    finally:
        pbar.update(1)

def ejecutar_escaneo(target, puertos_str, output_file=None, workers=200, timeout_val=1.5):
    results.clear()
    try:
        target_ip = socket.gethostbyname(target)
    except:
        print(f"{Colores.RED}[!] Error: No se pudo resolver {target}{Colores.ENDC}")
        return

    sistema, ttl = detect_os(target_ip)
    print(f"\n[*] Objetivo: {Colores.CYAN}{target}{Colores.ENDC} ({target_ip})")
    print(f"[*] SO Probable: {Colores.YELLOW}{sistema}{Colores.ENDC} (TTL: {ttl})")
    
    # Procesar rango
    if '-' in puertos_str:
        s, e = map(int, puertos_str.split('-'))
        ports = list(range(s, min(e + 1, 65536)))
    elif ',' in puertos_str:
        ports = list(map(int, puertos_str.split(',')))
    else:
        ports = [int(puertos_str)]

    print(f"[*] Escaneando {len(ports)} puertos ({workers} hilos / {timeout_val}s timeout)...\n")
    start_time = time.time()
    
    with tqdm(total=len(ports), unit="port", desc=f"{Colores.BOLD}Progreso{Colores.ENDC}", bar_format="{l_bar}{bar:30}{r_bar}") as pbar:
        with ThreadPoolExecutor(max_workers=workers) as executor:
            for p in ports:
                executor.submit(scan_port, target_ip, p, pbar, timeout_val)

    duration = round(time.time() - start_time, 2)
    print(f"\n{Colores.CYAN}--- Escaneo completado en {duration}s ---{Colores.ENDC}")
    
    if output_file:
        guardar_reporte(target, target_ip, sistema, output_file)

def guardar_reporte(target, ip, os, file):
    with open(file, 'w') as f:
        f.write(f"JakiScanner Report | {datetime.now()}\nTarget: {target} ({ip})\nOS: {os}\n" + "="*40 + "\n")
        for r in results:
            f.write(f"Port: {r['puerto']:<6} | Svc: {r['servicio']:<15}\n")
    print(f"{Colores.GREEN}[+] Reporte generado: {file}{Colores.ENDC}")

def mostrar_menu():
    print_banner()
    print(f"{Colores.BOLD}MENÚ INTERACTIVO:{Colores.ENDC}")
    print("1. Escaneo Rápido (1-100)")
    print("2. Escaneo Estándar (1-1024)")
    print("3. Escaneo Completo (1-65535)")
    print("4. Escaneo Personalizado")
    print("5. Salir")
    
    op = input(f"\n{Colores.YELLOW}Selecciona una opción: {Colores.ENDC}")
    if op == '5': sys.exit()
    
    target = input(f"{Colores.YELLOW}Introduce IP o Dominio: {Colores.ENDC}")
    save_input = input(f"{Colores.YELLOW}¿Guardar reporte? (nombre o Enter para No): {Colores.ENDC}")
    save = save_input if save_input else None
    
    # Lógica de perfiles de velocidad para la Opción 3
    if op == '3':
        print(f"\n{Colores.BOLD}VELOCIDAD DE ESCANEO:{Colores.ENDC}")
        print("A. Lento (Fiable/Internet) -> 50 hilos")
        print("B. Medio (Normal)           -> 200 hilos")
        print("C. Rápido (Agresivo/Local)  -> 500 hilos")
        v_op = input(f"\n{Colores.YELLOW}Selecciona velocidad [A/B/C]: {Colores.ENDC}").upper()
        
        if v_op == 'A': workers, t_out = 50, 2.5
        elif v_op == 'C': workers, t_out = 500, 0.7
        else: workers, t_out = 200, 1.5 # Opción B por defecto
        
        ejecutar_escaneo(target, "1-65535", save, workers, t_out)
    
    elif op == '1': ejecutar_escaneo(target, "1-100", save)
    elif op == '2': ejecutar_escaneo(target, "1-1024", save)
    elif op == '4':
        p = input(f"{Colores.YELLOW}Rango de puertos (ej: 80,443 o 1-5000): {Colores.ENDC}")
        ejecutar_escaneo(target, p, save)
    
    input(f"\n{Colores.CYAN}Presiona ENTER para volver al menú...{Colores.ENDC}")
    subprocess.run(['clear'])
    mostrar_menu()

def main():
    if len(sys.argv) > 1:
        print_banner()
        # Aquí podrías añadir lógica CLI si quieres, por ahora lanzamos menú
        mostrar_menu()
    else:
        subprocess.run(['clear'])
        mostrar_menu()

if __name__ == "__main__":
    try: main()
    except KeyboardInterrupt:
        print(f"\n{Colores.RED}[!] Escaneo abortado.{Colores.ENDC}")
        sys.exit(0)
