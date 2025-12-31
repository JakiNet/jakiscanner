#!/bin/bash

# --- Colores ---
CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'
BOLD='\033[1m'

# 1. VALIDACIÓN DE PERMISOS (NUEVO)
if [ "$EUID" -ne 0 ]; then 
  echo -e "${RED}${BOLD}[!] ERROR: Se requieren privilegios de administrador.${NC}"
  echo -e "${CYAN}Por favor, ejecuta el instalador usando: ${WHITE}sudo ./install.sh${NC}"
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
echo -e "      INSTALANDO JAKISCANNER GLOBAL       "
echo -e "==========================================${NC}\n"

# 2. Instalación de Dependencias
echo -n -e "➜ Instalando librerías necesarias... "
(pip3 install tqdm --break-system-packages --user > /dev/null 2>&1) &
spinner $!
echo -e "${GREEN}[OK]${NC}"

# 3. Permisos y Registro
echo -n -e "➜ Registrando comando en el sistema... "
chmod +x jakiscanner
# Ya no necesitamos poner sudo aquí adentro porque el script entero corre como root
if cp jakiscanner /usr/local/bin/jakiscanner > /dev/null 2>&1; then
    echo -e "${GREEN}[OK]${NC}"
else
    echo -e "${RED}[ERROR]${NC}"
    exit 1
fi

echo -e "\n${BOLD}${GREEN}¡Listo! Ahora puedes usar '${CYAN}jakiscanner${GREEN}' en cualquier terminal.${NC}"
