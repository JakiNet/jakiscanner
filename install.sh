#!/bin/bash

# --- Configuración de Colores ---
CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # Sin color
BOLD='\033[1m'

# --- Función para mostrar un "Spinner" (indicador de carga) ---
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    echo -n " "
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# --- Limpiar pantalla al iniciar ---
clear
echo -e "${CYAN}${BOLD}=========================================="
echo -e "      INSTALADOR DE DEPENDENCIAS          "
echo -e "==========================================${NC}\n"

# 1. Actualización de Repositorios
echo -n -e "${YELLOW}➜${NC} Actualizando repositorios... "
(sudo apt-get update -y > /dev/null 2>&1) & 
spinner $!
echo -e "${GREEN}[OK]${NC}"

# 2. Instalación de Python y Pip
echo -n -e "${YELLOW}➜${NC} Verificando Python y Pip...  "
(sudo apt-get install -y python3 python3-pip python3-venv > /dev/null 2>&1) &
spinner $!
echo -e "${GREEN}[OK]${NC}"

# 3. Instalación de tqdm
echo -n -e "${YELLOW}➜${NC} Instalando librería tqdm...  "
# Intentamos la instalación silenciosa
(pip3 install tqdm --break-system-packages --user > /dev/null 2>&1) &
spinner $!

# Verificación final
if python3 -c "import tqdm" > /dev/null 2>&1; then
    echo -e "${GREEN}[INSTALADO]${NC}"
    echo -e "\n${BOLD}${GREEN}¡Todo listo! El sistema está configurado.${NC}"
else
    echo -e "${RED}[ERROR]${NC}"
    echo -e "\n${RED}Algo salió mal. Intenta ejecutar: sudo apt install python3-tqdm${NC}"
fi

echo -e "${CYAN}==========================================${NC}"
