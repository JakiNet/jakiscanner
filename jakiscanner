#!/usr/bin/env python3
import socket
import argparse
import threading
import time
from datetime import datetime
import sys
import subprocess
import re
import json

# Intentar importar tqdm, si no está, el script avisará
try:
    from tqdm import tqdm
except ImportError:
    print("\n[!] Error: La librería 'tqdm' no está instalada.")
    print("[*] Ejecuta: pip install tqdm\n")
    sys.exit(1)

# --- Configuración de Colores ---
class Colores:
    CYAN = '\033[96m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'

# --- Diccionario de Servicios Estándar ---
SERVICIOS_COMUNES = {
    21: "FTP", 22: "SSH", 23: "Telnet", 25: "SMTP", 53: "DNS",
    80: "HTTP", 110: "POP3", 111: "RPCBind", 135: "MSRPC",
    139: "NetBIOS", 143: "IMAP", 443: "HTTPS", 445: "SMB/MS-DS",
    993: "IMAPS", 995: "POP3S", 1723: "PPTP", 3306: "MySQL",
    3389: "RDP", 5432: "PostgreSQL", 5900: "VNC", 8080: "HTTP-Proxy",
    4444: "Metasploit", 60000: "Deep-Backdoor"
}

def print_banner():
    # La 'r' al principio es la solución al SyntaxWarning
    banner = r"""
     _ ___  _  __ _  ___  ___  __  __ _  __ _  ____ ___ 
  | |/ _ \| |/ /| |/ __|/ __|/ _\|  \| ||  \| ||  __| _ \
__| |  _  |   < | |\__ \ (__| (_ | .  || .  ||  __|   / 
\__/ \__| |_|\_\_|\____|\___|\__/|_|\_||_|\_||____|_|_/
                                  v1.0 - TCP Logic Scanner
    """   
    print(f"{Colores.CYAN}{banner}{Colores.ENDC}")

def detect_os(ip):
    """Detecta el SO basado en el valor del TTL."""
    try:
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
    """Escanea un puerto y captura el banner si es posible."""
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(1.5)
        result = sock.connect_ex((target_ip, port))
        
        if result == 0:
            banner = ""
            try:
                banner = sock.recv(1024).decode('utf-8', errors='ignore').strip().replace('\n', ' ')
            except:
                pass
            
            nombre_serv = SERVICIOS_COMUNES.get(port, "Desconocido")
            
            with print_lock:
                # pbar.write permite imprimir sin romper la barra de progreso
                pbar.write(f"  [{Colores.GREEN}+{Colores.ENDC}] Puerto {Colores.BOLD}{port:<5}{Colores.ENDC} ({Colores.CYAN}{nombre_serv:<12}{Colores.ENDC}) -> {Colores.GREEN}ABIERTO{Colores.ENDC} {Colores.YELLOW if banner else ''}{'[' + banner + ']' if banner else ''}{Colores.ENDC}")
                results.append({
                    "puerto": port,
                    "servicio": nombre_serv,
                    "banner": banner
                })
        sock.close()
    except:
        pass
    finally:
        pbar.update(1)

def ejecutar_escaneo(target, puertos_str, output_file=None):
    results.clear()
    try:
        target_ip = socket.gethostbyname(target)
    except:
        print(f"{Colores.RED}[!] Error: No se pudo resolver el host {target}{Colores.ENDC}")
        return

    sistema, ttl = detect_os(target_ip)
    print(f"\n[*] Objetivo: {Colores.CYAN}{target}{Colores.ENDC} ({target_ip})")
    print(f"[*] SO Probable: {Colores.YELLOW}{sistema}{Colores.ENDC} (TTL: {ttl})")
    
    # Manejo de rangos y listas de puertos
    if '-' in puertos_str:
        s, e = map(int, puertos_str.split('-'))
        ports = list(range(s, e + 1))
    elif ',' in puertos_str:
        ports = list(map(int, puertos_str.split(',')))
    else:
        ports = [int(puertos_str)]

    print(f"[*] Escaneando {len(ports)} puertos con hilos concurrentes...\n")
    
    start_time = time.time()
    
    # Barra de progreso tqdm
    with tqdm(total=len(ports), unit="port", desc=f"{Colores.BOLD}Progreso{Colores.ENDC}", leave=True, bar_format="{l_bar}{bar:30}{r_bar}") as pbar:
        threads = []
        for p in ports:
            t = threading.Thread(target=scan_port, args=(target_ip, p, pbar))
            t.start()
            threads.append(t)
            # Control de saturación de hilos
            if len(threads) % 150 == 0:
                time.sleep(0.01)
        
        for t in threads:
            t.join()

    duration = round(time.time() - start_time, 2)
    print(f"\n{Colores.CYAN}--- Escaneo completado en {duration}s ---{Colores.ENDC}")
    print(f"[*] Puertos abiertos encontrados: {Colores.BOLD}{len(results)}{Colores.ENDC}")

    # Guardado de archivos
    if output_file:
        if output_file.endswith('.json'):
            data = {"target": target, "ip": target_ip, "os": sistema, "scan_date": str(datetime.now()), "open_ports": results}
            with open(output_file, 'w') as f:
                json.dump(data, f, indent=4)
        else:
            with open(output_file, 'w') as f:
                f.write(f"Reporte JakiScanner v2.0\nFecha: {datetime.now()}\nObjetivo: {target} ({target_ip})\nSO Probable: {sistema}\n" + "="*50 + "\n")
                for r in results:
                    f.write(f"Puerto: {r['puerto']:<6} | Servicio: {r['servicio']:<15} | Banner: {r['banner']}\n")
        
        print(f"{Colores.GREEN}[+] Resultados guardados en: {Colores.BOLD}{output_file}{Colores.ENDC}")

def mostrar_menu():
    print_banner()
    print(f"{Colores.BOLD}MENÚ INTERACTIVO:{Colores.ENDC}")
    print("1. Escaneo Rápido (1-100)")
    print("2. Escaneo Estándar (1-1024)")
    print("3. Escaneo Completo (1-65535)")
    print("4. Escaneo Personalizado")
    print("5. Salir")
    
    opcion = input(f"\n{Colores.YELLOW}Selecciona una opción: {Colores.ENDC}")
    
    if opcion == '5':
        print(f"{Colores.CYAN}¡Gracias por usar JakiScanner! Saliendo...{Colores.ENDC}")
        sys.exit()
    
    target = input(f"{Colores.YELLOW}Introduce IP o Dominio: {Colores.ENDC}")
    save = input(f"{Colores.YELLOW}¿Guardar reporte? (ej: resultado.txt / resultado.json / No): {Colores.ENDC}")
    out = save if save.lower() != 'no' else None

    if opcion == '1': ejecutar_escaneo(target, "1-100", out)
    elif opcion == '2': ejecutar_escaneo(target, "1-1024", out)
    elif opcion == '3': ejecutar_escaneo(target, "1-65535", out)
    elif opcion == '4':
        p = input(f"{Colores.YELLOW}Rango de puertos (ej: 22,80,443 o 1-5000): {Colores.ENDC}")
        ejecutar_escaneo(target, p, out)
    
    input(f"\n{Colores.CYAN}Presiona ENTER para volver al menú...{Colores.ENDC}")
    subprocess.run(['clear'])
    mostrar_menu()

def main():
    # Si hay argumentos, usar CLI. Si no, usar Menú.
    if len(sys.argv) > 1:
        parser = argparse.ArgumentParser(description="JakiScanner v2.0 - Escáner de Puertos Profesional")
        parser.add_argument("-t", "--target", help="IP o dominio del objetivo", required=True)
        parser.add_argument("-p", "--ports", help="Rango de puertos (ej: 1-1000 o 80,443)", default="1-1024")
        parser.add_argument("-o", "--output", help="Archivo de salida (.txt o .json)")
        args = parser.parse_args()
        print_banner()
        ejecutar_escaneo(args.target, args.ports, args.output)
    else:
        subprocess.run(['clear'])
        mostrar_menu()

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print(f"\n{Colores.RED}[!] Escaneo interrumpido por el usuario.{Colores.ENDC}")
        sys.exit(0)
