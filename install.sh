#!/bin/bash

# --- Colores ---
CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'
BOLD='\033[1m'

# 1. Forzar que se corra con sudo
if [ "$EUID" -ne 0 ]; then 
  echo -e "${RED}${BOLD}[!] Error: Ejecuta con sudo.${NC}"
  echo -e "Uso: sudo ./install.sh"
  exit 1
fi

spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

clear
echo -e "${CYAN}${BOLD}=========================================="
echo -e "      INSTALADOR UNIVERSAL JAKISCANNER    "
echo -e "==========================================${NC}\n"

# 2. Instalar dependencias silenciando errores de sistema (PEP 668)
echo -n -e "➜ Instalando dependencias de Python...  "
(apt-get update -y > /dev/null 2>&1 && \
 apt-get install -y python3-tqdm > /dev/null 2>&1 || \
 pip3 install tqdm --break-system-packages --user > /dev/null 2>&1) &
spinner $!
echo -e "${GREEN}[OK]${NC}"

# 3. Registro Global (Independiente del usuario)
echo -n -e "➜ Registrando comando en el sistema...  "
chmod +x jakiscanner
# Copiamos a /usr/local/bin para que sea accesible por TODOS los usuarios
if cp jakiscanner /usr/local/bin/jakiscanner > /dev/null 2>&1; then
    echo -e "${GREEN}[OK]${NC}"
else
    echo -e "${RED}[FALLÓ]${NC}"
    exit 1
fi

# 4. Limpieza de entorno
echo -n -e "➜ Optimizando configuración...          "
# Esto evita que el usuario vea errores de Git en el futuro si clona tu repo
git config --global --add safe.directory $(pwd) > /dev/null 2>&1
echo -e "${GREEN}[OK]${NC}"

echo -e "\n${BOLD}${GREEN}¡Instalación exitosa!${NC}"
echo -e "Escribe ${CYAN}jakiscanner${NC} en cualquier terminal para empezar."
