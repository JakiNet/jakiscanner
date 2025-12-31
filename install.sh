#!/bin/bash

# --- Colores ---
CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'
BOLD='\033[1m'

# 1. Forzar Root
if [ "$EUID" -ne 0 ]; then 
  echo -e "${RED}${BOLD}[!] Error: Se requiere sudo para instalar globalmente.${NC}"
  exit 1
fi

clear
echo -e "${CYAN}=========================================="
echo -e "    INSTALACIÓN AUTOMÁTICA: JAKISCANNER   "
echo -e "==========================================${NC}\n"

# 2. Identificar el archivo fuente (por si tiene .py o no)
if [ -f "jakiscanner.py" ]; then
    SOURCE="jakiscanner.py"
elif [ -f "jakiscanner" ]; then
    SOURCE="jakiscanner"
else
    echo -e "${RED}[!] Error: No se encontró el archivo del script en esta carpeta.${NC}"
    exit 1
fi

# 3. Instalación de Dependencias
echo -e "➜ Instalando dependencias de Python..."
apt-get update -y > /dev/null 2>&1
apt-get install -y python3-tqdm > /dev/null 2>&1
pip3 install tqdm --break-system-packages --user > /dev/null 2>&1

# 4. Registro del comando
echo -e "➜ Registrando comando en /usr/local/bin..."
# Copiamos el archivo quitándole la extensión .py si la tuviera
cp "$SOURCE" /usr/local/bin/jakiscanner
chmod +x /usr/local/bin/jakiscanner

# 5. TRUCO DE COMPATIBILIDAD (Para que funcione al instante)
# Creamos un enlace simbólico por si el PATH tiene prioridades
ln -sf /usr/local/bin/jakiscanner /usr/bin/jakiscanner

echo -e "\n${GREEN}${BOLD}¡CONFIGURACIÓN COMPLETADA!${NC}"
echo -e "${CYAN}------------------------------------------${NC}"
echo -e "Para empezar a usarlo ahora mismo:"
echo -e "1. Escribe: ${BOLD}rehash${NC} (si usas ZSH/Kali)"
echo -e "2. O simplemente escribe: ${BOLD}jakiscanner${NC}"
echo -e "${CYAN}------------------------------------------${NC}"
