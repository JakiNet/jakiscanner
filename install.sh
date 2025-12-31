#!/bin/bash

# --- CONFIGURACIÓN DE LA HERRAMIENTA ---
TOOL_NAME="jakiscanner"
PY_FILE="jakiscanner.py"

# --- COLORES ---
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
GREEN='\033[0;32m'
RED='\033[0;31m'
WHITE='\033[1;37m'
NC='\033[0m'
BOLD='\033[1m'

# --- FUNCIONES VISUALES ---

# 1. El Spinner (Para procesos de fondo)
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf "  ${PURPLE}[%c]${NC}  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# 2. Barra de Progreso (Para simular carga de sistema)
progress_bar() {
    local duration=$1
    local width=30
    echo -ne "  "
    for ((i=0; i<=width; i++)); do
        let fill=i*100/width
        printf "\r  ${CYAN}▕"
        for ((j=0; j<i; j++)); do printf "█"; done
        for ((j=i; j<width; j++)); do printf " "; done
        printf "▏${NC} $fill%%"
        sleep 0.04
    done
    echo -e ""
}

# --- INICIO DEL SCRIPT ---

if [ "$EUID" -ne 0 ]; then 
  echo -e "${RED}${BOLD}[!] Error: Ejecuta con sudo.${NC}"
  exit 1
fi

clear
echo -e "${PURPLE}${BOLD}"
echo "      ██╗ █████╗ ██╗  ██╗██╗███╗   ██╗███████╗████████╗"
echo "      ██║██╔══██╗██║ ██╔╝██║████╗  ██║██╔════╝╚══██╔══╝"
echo "      ██║███████║█████╔╝ ██║██╔██╗ ██║█████╗     ██║   "
echo "      ██║██╔══██╗██╔═██╗ ██║██║╚██╗██║██╔══╝     ██║   "
echo "      ██║██║  ██║██║  ██╗██║██║ ╚████║███████╗   ██║   "
echo "      ╚═╝╚═╝  ██║╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝╚══════╝   ╚═╝   "
echo -e "              ${WHITE}INFRASTRUCTURE SETUP${NC}\n"

# PASO 1: Dependencias
echo -ne "${CYAN}[*]${NC} Descargando paquetes de sistema...   "
(apt-get update -y && apt-get install -y python3-tqdm) > /dev/null 2>&1 &
spinner $!
echo -e "${GREEN}HECHO${NC}"

# PASO 2: Sincronización
echo -e "${CYAN}[*]${NC} Sincronizando archivos en /opt/$TOOL_NAME..."
progress_bar
mkdir -p /opt/$TOOL_NAME
cp -f "$PY_FILE" "/opt/$TOOL_NAME/$PY_FILE"
chmod +x "/opt/$TOOL_NAME/$PY_FILE"

# PASO 3: Binario
echo -ne "${CYAN}[*]${NC} Creando enlace simbólico...          "
ln -sf "/opt/$TOOL_NAME/$PY_FILE" "/usr/local/bin/$TOOL_NAME"
sleep 0.5
echo -e "${GREEN}HECHO${NC}"

# PASO 4: Permisos Finales
echo -ne "${CYAN}[*]${NC} Aplicando políticas de ejecución...  "
if id "jaki" &>/dev/null; then
    chown -R jaki:jaki "/opt/$TOOL_NAME"
fi
chmod 755 "/opt/$TOOL_NAME/$PY_FILE"
sleep 0.5
echo -e "${GREEN}HECHO${NC}"

# --- MENSAJE FINAL ---
echo -e "\n${GREEN}${BOLD}¡CONFIGURACIÓN FINALIZADA!${NC}"
echo -e "${CYAN}--------------------------------------------------${NC}"
echo -e " ${WHITE}Comando:${NC} ${BOLD}$TOOL_NAME${NC}"
echo -e " ${WHITE}Ruta:${NC}    /opt/$TOOL_NAME/"
echo -e "${CYAN}--------------------------------------------------${NC}"
