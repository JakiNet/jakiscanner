#!/bin/bash

# --- Colores ---
CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'
BOLD='\033[1m'

if [ "$EUID" -ne 0 ]; then 
  echo -e "${RED}${BOLD}[!] Error: Ejecuta con sudo para la instalación.${NC}"
  exit 1
fi

REAL_USER=$SUDO_USER
USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

clear
echo -e "${CYAN}=========================================="
echo -e "    INSTALADOR PROFESIONAL: JAKISCANNER   "
echo -e "==========================================${NC}\n"

# 1. Copiar archivo
SOURCE=$(ls jakiscanner* | grep -v "install.sh" | head -n 1)
cp "$SOURCE" /usr/local/bin/jakiscanner

# 2. EL FIX DEFINITIVO DE PERMISOS
# 755 = Propietario(Leer/Escribir/Ejecutar) | Grupo y Otros(Leer/Ejecutar)
# Esto elimina el "Errno 13 Permission Denied" para siempre.
chmod 755 /usr/local/bin/jakiscanner

# 3. Crear Alias para mayor compatibilidad
add_alias() {
    local config_file=$1
    if [ -f "$config_file" ]; then
        sed -i '/alias jakiscanner=/d' "$config_file"
        echo "alias jakiscanner='/usr/local/bin/jakiscanner'" >> "$config_file"
        chown $REAL_USER:$REAL_USER "$config_file"
    fi
}

add_alias "$USER_HOME/.bashrc"
add_alias "$USER_HOME/.zshrc"

echo -e "➜ Instalando dependencias..."
apt-get update -y > /dev/null 2>&1
apt-get install -y python3-tqdm > /dev/null 2>&1

echo -e "\n${GREEN}${BOLD}¡INSTALACIÓN COMPLETADA!${NC}"
echo -e "Escribe ${CYAN}source ~/.zshrc${NC} o abre una nueva terminal."
echo -e "Luego lanza tu herramienta: ${BOLD}jakiscanner${NC}"
