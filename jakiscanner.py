#!/usr/bin/env python3
import threading
import time
from datetime import datetime
import sys
import subprocess
import re
import socket
from concurrent.futures import ThreadPoolExecutor

# Intentar importar tqdm
try:
    from tqdm import tqdm
except ImportError:
    print("\n[!] Error: La librería 'tqdm' no está instalada.")
    print("[*] Ejecuta: sudo pip3 install tqdm --break-system-packages\n")
    sys.exit(1)

class Colores:
    CYAN = '\033[96m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'

# --- DICCIONARIO MASIVO DE SERVICIOS (v2.5) ---
SERVICIOS_COMUNES = {
    # Fundamentales
    20: "FTP-Data", 21: "FTP", 22: "SSH", 23: "Telnet", 25: "SMTP", 
    43: "Whois", 53: "DNS", 67: "DHCP-S", 68: "DHCP-C", 69: "TFTP",
    80: "HTTP", 110: "POP3", 111: "RPCBind", 119: "NNTP", 123: "NTP",
    135: "MSRPC", 137: "NetBIOS-NS", 138: "NetBIOS-DG", 139: "NetBIOS-SSN",
    143: "IMAP", 161: "SNMP", 179: "BGP", 389: "LDAP", 443: "HTTPS",
    445: "SMB/AD", 465: "SMTPS", 500: "ISAKMP", 514: "Syslog", 515: "LPD",
    543: "KLogin", 544: "KShell", 548: "AFP (Apple)", 587: "SMTP-Sub",
    631: "IPP (Print)", 636: "LDAPS", 873: "Rsync", 990: "FTPS",
    993: "IMAPS", 995: "POP3S",
    
    # Bases de Datos
    1433: "MSSQL", 1434: "MSSQL-Mon", 1521: "Oracle", 2483: "Oracle-TTC",
    3306: "MySQL", 5432: "PostgreSQL", 5984: "CouchDB", 6379: "Redis",
    7000: "Cassandra", 7001: "Cassandra", 9042: "Cassandra-Native",
    9200: "Elasticsearch", 9300: "Elastic-Nodes", 27017: "MongoDB",
    27018: "Mongo-Shard", 28017: "Mongo-Web",
    
    # Administración y Remoto
    1723: "PPTP", 2049: "NFS", 3389: "RDP", 5555: "ADB (Android)",
    5631: "PCAnywhere", 5900: "VNC", 5901: "VNC-1", 5985: "WinRM-HTTP",
    5986: "WinRM-HTTPS", 6000: "X11", 10000: "Webmin",
    
    # Web / Apps / Proxies
    1080: "SOCKS", 1194: "OpenVPN", 3000: "NodeJS/React", 3128: "Squid",
    4000: "Ghost/Games", 4444: "Metasploit", 5000: "Flask/Docker",
    8000: "Django/Alt", 8008: "HTTP-Alt", 8080: "HTTP-Proxy",
    8081: "HTTP-Alt", 8443: "HTTPS-Alt", 8888: "Jupyter/CPanel",
    9000: "Portainer/PHP", 9090: "Cockpit", 32400: "Plex",
    
    # IoT / Telefonía / Otros
    1883: "MQTT", 5060: "SIP", 5061: "SIP-TLS", 8010: "XMPP",
    1337: "Wasted/Hacker-Alt", 32768: "Filenet", 49152: "Windows-Dynamic",
    60000: "Deep-Backdoor"
}

def print_banner():
    banner = r"""
     _ ___  _  __ _  ___  ___  __  __ _  __ _  ____ ___ 
  | |/ _ \| |/ /| |/ __|/ __|/ _\|  \| ||  \| ||  __| _ \
__| |  _  |   < | |\__ \ (__| (_ | .  || .  ||  __|   / 
\__/ \__| |_|\_\_|\____|\___|\__/|_|\_||_|\_||____|_|_/
                                v2.5 - Massive DB & Speed Menu
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
            version = ""
            try:
                # Intento de Banner Grabbing
                sock.send(b"HEAD / HTTP/1.0\r\n\r\n") 
                banner = sock.recv(512).decode('utf-8', errors='ignore').strip()
                if banner:
                    version = banner.split('\n')[0][:40]
            except: pass
            
            display_version = f"({Colores.YELLOW}{version}{Colores.ENDC})" if version else ""
            nombre = SERVICIOS_COMUNES.get(puerto, "Desconocido")
            
            with print_lock:
                pbar.write(f"  [{Colores.GREEN}+{Colores.ENDC}] Puerto {Colores.BOLD}{puerto:<5}{Colores.ENDC} ({Colores.CYAN}{nombre:<12}{Colores.ENDC}) {display_version}")
                results.append({"puerto": puerto, "servicio": nombre, "version": version})
        sock.close()
    except: pass
    finally:
        pbar.update(1)

def ejecutar_escaneo(target, puertos_str, output_file=None, workers=300, timeout_val=2.0):
    results.clear()
    try:
        target_ip = socket.gethostbyname(target)
    except:
        print(f"{Colores.RED}[!] Error: IP inválida.{Colores.ENDC}")
        return

    sistema, ttl = detect_os(target_ip)
    print(f"\n[*] Objetivo: {Colores.CYAN}{target}{Colores.ENDC} ({target_ip})")
    print(f"[*] SO: {Colores.YELLOW}{sistema}{Colores.ENDC} (TTL: {ttl})")
    
    if '-' in puertos_str:
        s, e = map(int, puertos_str.split('-'))
        ports = list(range(s, min(e + 1, 65536)))
    elif ',' in puertos_str:
        ports = list(map(int, puertos_str.split(',')))
    else:
        ports = [int(puertos_str)]

    print(f"[*] Escaneando {len(ports)} puertos con {workers} hilos...\n")
    start_time = time.time()
    
    with tqdm(total=len(ports), unit="port", desc=f"{Colores.BOLD}Escaneo{Colores.ENDC}", bar_format="{l_bar}{bar:25}{r_bar}") as pbar:
        with ThreadPoolExecutor(max_workers=workers) as executor:
            for p in ports:
                executor.submit(scan_port, target_ip, p, pbar, timeout_val)

    duration = round(time.time() - start_time, 2)
    print(f"\n{Colores.CYAN}--- Completado en {duration}s | Encontrados: {len(results)} ---{Colores.ENDC}")
    
    if output_file:
        guardar_reporte(target, target_ip, sistema, output_file)

def guardar_reporte(target, ip, os, file):
    with open(file, 'w') as f:
        f.write(f"JakiScanner v2.5 | {datetime.now()}\nTarget: {target} ({ip})\nOS: {os}\n" + "="*50 + "\n")
        for r in results:
            f.write(f"Puerto: {r['puerto']:<6} | Svc: {r['servicio']:<15} | Ver: {r['version']}\n")
    print(f"{Colores.GREEN}[+] Reporte: {file}{Colores.ENDC}")

# --- Nueva función de menú de velocidad ---
def seleccionar_velocidad():
    print(f"\n{Colores.BOLD}OPCIONES DE VELOCIDAD:{Colores.ENDC}")
    print("A. Lento (Más fiable, 50 hilos)")
    print("B. Normal (Equilibrado, 200 hilos)")
    print("C. Rápido (Agresivo, 500 hilos)")
    v_op = input(f"\n{Colores.YELLOW}Selecciona velocidad [A/B/C]: {Colores.ENDC}").upper()
    
    if v_op == 'A': return 50, 2.5
    if v_op == 'C': return 500, 0.8
    return 200, 1.5 # Opción B por defecto

def mostrar_menu():
    print_banner()
    print("1. Rápido (Top 100)")
    print("2. Estándar (Top 1024)")
    print("3. Full (65535)")
    print("4. Personalizado")
    print("5. Salir")
    
    op = input(f"\n{Colores.YELLOW}Selecciona: {Colores.ENDC}")
    if op == '5': sys.exit()
    
    target = input(f"{Colores.YELLOW}IP/Dominio: {Colores.ENDC}")
    save_in = input(f"{Colores.YELLOW}Guardar (ej: scan.txt / Enter No): {Colores.ENDC}")
    save = save_in if save_in else None
    
    if op == '1': 
        ejecutar_escaneo(target, "1-100", save)
    elif op == '2': 
        ejecutar_escaneo(target, "1-1024", save)
    elif op == '3': 
        w, t = seleccionar_velocidad()
        ejecutar_escaneo(target, "1-65535", save, workers=w, timeout_val=t)
    elif op == '4':
        p = input(f"{Colores.YELLOW}Puertos (ej: 22,80,443): {Colores.ENDC}")
        w, t = seleccionar_velocidad()
        ejecutar_escaneo(target, p, save, workers=w, timeout_val=t)
    
    input(f"\n{Colores.CYAN}Presiona ENTER para continuar...{Colores.ENDC}")
    subprocess.run(['clear'])
    mostrar_menu()

if __name__ == "__main__":
    try: 
        subprocess.run(['clear'])
        mostrar_menu()
    except KeyboardInterrupt: 
        print(f"\n{Colores.RED}[!] Saliendo...{Colores.ENDC}")
        sys.exit(0)
