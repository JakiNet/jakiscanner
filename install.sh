#!/bin/bash

# --- Colores ---
CYAN='\033[0;36m'
GREEN='\033[0;32m'
NC='\033[0m'
BOLD='\033[1m'

# Validar Root
if [ "$EUID" -ne 0 ]; then 
  echo -e "\033[0;31m[!] Error: Ejecuta con sudo: sudo ./install.sh\033[0m"
  exit 1
fi

clear
echo -e "${CYAN}${BOLD}=========================================="
echo -e "         INSTALADOR DE JAKISCANNER        "
echo -e "==========================================${NC}"

# 1. Instalar dependencias
echo -e "\n${CYAN}➜${NC} Preparando entorno..."
apt-get update -y > /dev/null 2>&1
apt-get install -y python3-tqdm > /dev/null 2>&1
pip3 install tqdm --break-system-packages --user > /dev/null 2>&1

# 2. Localizar archivo
SOURCE=$(ls jakiscanner* | grep -v "install.sh" | head -n 1)

# 3. Registro Global
echo -e "${CYAN}➜${NC} Registrando comando en el sistema..."
cp "$SOURCE" /usr/local/bin/jakiscanner
chmod 755 /usr/local/bin/jakiscanner

# Forzar que sea accesible desde cualquier ruta
ln -sf /usr/local/bin/jakiscanner /usr/bin/jakiscanner

# 4. Mensaje Final (Limpio y directo)
echo -e "\n${GREEN}${BOLD}¡INSTALACIÓN COMPLETADA!${NC}"
echo -e "${CYAN}------------------------------------------${NC}"
echo -e "Ya puedes usar la herramienta escribiendo:"
echo -e "${BOLD}jakiscanner${NC}"
echo -e "${CYAN}------------------------------------------${NC}"
