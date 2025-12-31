import argparse
import threading
import time
from datetime import datetime
import sys
import subprocess
import re
import json
import socket  # <--- Agregado: ¡Fundamental para la red!

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

# --- Diccionario de Servicios Ampliado ---
SERVICIOS_COMUNES = {
    21: "FTP", 22: "SSH", 23: "Telnet", 25: "SMTP", 53: "DNS",
    80: "HTTP", 110: "POP3", 111: "RPCBind", 135: "MSRPC",
    139: "NetBIOS", 143: "IMAP", 443: "HTTPS", 445: "SMB/MS-DS",
    993: "IMAPS", 995: "POP3S", 1723: "PPTP", 2049: "NFS",
    3000: "NodeJS/React", 3003: "Dev-Micro", 3005: "Dev-Micro", 3006: "Dev-Micro",
    3306: "MySQL", 3389: "RDP", 5000: "Flask/Docker", 
    5331: "Backup-Svc", 5432: "PostgreSQL", 5900: "VNC", 
    6379: "Redis", 8000: "HTTP-Alt", 8080: "HTTP-Proxy",
    8081: "HTTP-Alt", 8082: "HTTP-Alt/Proxy", 8443: "HTTPS-Alt", 
    9000: "Portainer", 27017: "MongoDB", 4444: "Metasploit", 
    60000: "Deep-Backdoor"
}

def print_banner():
    banner = r"""
     _ ___  _  __ _  ___  ___  __  __ _  __ _  ____ ___ 
  | |/ _ \| |/ /| |/ __|/ __|/ _\|  \| ||  \| ||  __| _ \
__| |  _  |   < | |\__ \ (__| (_ | .  || .  ||  __|   / 
\__/ \__| |_|\_\_|\____|\___|\__/|_|\_||_|\_||____|_|_/
                                v2.0 - TCP Logic Scanner
    """   
    print(f"{Colores.CYAN}{banner}{Colores.ENDC}")
    print(f"{Colores.YELLOW}   Sincronizado con Infraestructura JakiNet{Colores.ENDC}\n")

def detect_os(ip):
    """Detecta el SO basado en el valor del TTL mediante un ping."""
    try:
        # Usamos un solo ping para rapidez
        process = subprocess.Popen(['ping', '-c', '1', '-W', '1', ip], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        out, _ = process.communicate()
        ttl_match = re.search(r"ttl=(\d+)", out.decode())
        if ttl_match:
            ttl = int(ttl_match.group(1))
            if ttl <= 64: return "Linux/Unix", ttl
            elif ttl <= 128: return "Windows", ttl
            else: return "Cisco/Network Device", ttl
    except: pass
    return "Desconocido", "N/A"

print_lock = threading.Semaphore(value=1)
results = []

def scan_port(target_ip, port, pbar):
    """Escanea un puerto, captura banner e identifica servicio."""
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(1.5)
        result = sock.connect_ex((target_ip, port))
        
        if result == 0:
            banner = ""
            try:
                # Intento de Banner Grabbing
                banner = sock.recv(1024).decode('utf-8', errors='ignore').strip().replace('\n', ' ')
            except: pass
            
            nombre_serv = SERVICIOS_COMUNES.get(port, "Desconocido")
            
            with print_lock:
                pbar.write(f"  [{Colores.GREEN}+{Colores.ENDC}] Puerto {Colores.BOLD}{port:<5}{Colores.ENDC} ({Colores.CYAN}{nombre_serv:<12}{Colores.ENDC}) -> {Colores.GREEN}ABIERTO{Colores.ENDC} {Colores.YELLOW + '[' + banner + ']' if banner else ''}{Colores.ENDC}")
                results.append({
                    "puerto": port,
                    "servicio": nombre_serv,
                    "banner": banner
                })
        sock.close()
    except: pass
    finally:
        pbar.update(1)

def ejecutar_escaneo(target, puertos_str, output_file=None):
    results.clear()
    try:
        target_ip = socket.gethostbyname(target)
    except:
        print(f"{Colores.RED}[!] Error: No se pudo resolver {target}{Colores.ENDC}")
        return

    sistema, ttl = detect_os(target_ip)
    print(f"[*] Objetivo: {Colores.CYAN}{target}{Colores.ENDC} ({target_ip})")
    print(f"[*] SO Probable: {Colores.YELLOW}{sistema}{Colores.ENDC} (TTL: {ttl})")
    
    # Procesar rango de puertos
    if '-' in puertos_str:
        s, e = map(int, puertos_str.split('-'))
        ports = list(range(s, min(e + 1, 65536)))
    elif ',' in puertos_str:
        ports = list(map(int, puertos_str.split(',')))
    else:
        ports = [int(puertos_str)]

    print(f"[*] Escaneando {len(ports)} puertos...\n")
    start_time = time.time()
    
    with tqdm(total=len(ports), unit="port", desc=f"{Colores.BOLD}Progreso{Colores.ENDC}", bar_format="{l_bar}{bar:30}{r_bar}") as pbar:
        threads = []
        for p in ports:
            t = threading.Thread(target=scan_port, args=(target_ip, p, pbar))
            t.daemon = True # Evita que el programa se cuelgue al salir
            t.start()
            threads.append(t)
            
            # Limitar ráfagas para no saturar el stack de red
            if len(threads) % 200 == 0:
                time.sleep(0.05)
        
        for t in threads:
            t.join()

    duration = round(time.time() - start_time, 2)
    print(f"\n{Colores.CYAN}--- Escaneo completado en {duration}s ---{Colores.ENDC}")
    
    if output_file:
        guardar_reporte(target, target_ip, sistema, output_file)

def guardar_reporte(target, ip, os, file):
    if file.endswith('.json'):
        data = {"target": target, "ip": ip, "os": os, "date": str(datetime.now()), "open_ports": results}
        with open(file, 'w') as f: json.dump(data, f, indent=4)
    else:
        with open(file, 'w') as f:
            f.write(f"JakiScanner Report | {datetime.now()}\nTarget: {target} ({ip})\nOS: {os}\n" + "="*40 + "\n")
            for r in results:
                f.write(f"Port: {r['puerto']:<6} | Svc: {r['servicio']:<15} | Banner: {r['banner']}\n")
    print(f"{Colores.GREEN}[+] Reporte generado: {Colores.BOLD}{file}{Colores.ENDC}")

def mostrar_menu():
    print_banner()
    print(f"{Colores.BOLD}MODOS DE ESCANEO:{Colores.ENDC}")
    print("1. Rápido (1-100)")
    print("2. Estándar (1-1024)")
    print("3. Full (1-65535)")
    print("4. Personalizado")
    print("5. Salir")
    
    op = input(f"\n{Colores.YELLOW}Selecciona: {Colores.ENDC}")
    if op == '5': sys.exit()
    
    target = input(f"{Colores.YELLOW}IP/Dominio: {Colores.ENDC}")
    save = input(f"{Colores.YELLOW}Guardar como (ej: scan.json / scan.txt / Enter para omitir): {Colores.ENDC}")
    
    if op == '1': ejecutar_escaneo(target, "1-100", save)
    elif op == '2': ejecutar_escaneo(target, "1-1024", save)
    elif op == '3': ejecutar_escaneo(target, "1-65535", save)
    elif op == '4':
        p = input(f"{Colores.YELLOW}Puertos (ej: 80,443 o 1-5000): {Colores.ENDC}")
        ejecutar_escaneo(target, p, save)
    
    input(f"\n{Colores.CYAN}Presiona ENTER para volver...{Colores.ENDC}")
    subprocess.run(['clear'])
    mostrar_menu()

def main():
    if len(sys.argv) > 1:
        parser = argparse.ArgumentParser()
        parser.add_argument("-t", "--target", required=True)
        parser.add_argument("-p", "--ports", default="1-1024")
        parser.add_argument("-o", "--output")
        args = parser.parse_args()
        print_banner()
        ejecutar_escaneo(args.target, args.ports, args.output)
    else:
        subprocess.run(['clear'])
        mostrar_menu()

if __name__ == "__main__":
    try: main()
    except KeyboardInterrupt:
        print(f"\n{Colores.RED}[!] Abortado.{Colores.ENDC}")
        sys.exit(0)
