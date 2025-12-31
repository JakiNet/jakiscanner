#!/bin/bash

# --- Colores ---
CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'
BOLD='\033[1m'

# 1. Validar Root
if [ "$EUID" -ne 0 ]; then 
  echo -e "${RED}${BOLD}[!] Debes ejecutar con sudo: sudo ./install.sh${NC}"
  exit 1
fi

# 2. Detectar al usuario real (quien ejecutó sudo)
REAL_USER=$SUDO_USER
USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

clear
echo -e "${CYAN}=========================================="
echo -e "    INSTALADOR PRO: JAKISCANNER           "
echo -e "==========================================${NC}\n"

# 3. Dependencias
echo -n "➜ Instalando librerías... "
apt-get update -y > /dev/null 2>&1
apt-get install -y python3-tqdm > /dev/null 2>&1
echo -e "${GREEN}[OK]${NC}"

# 4. Registro del archivo
SOURCE=$(ls jakiscanner* | grep -v "install.sh" | head -n 1)
cp "$SOURCE" /usr/local/bin/jakiscanner
chmod +x /usr/local/bin/jakiscanner

# 5. LA MAGIA DE JAKISNIPPETS: Inyectar en la configuración de la terminal
echo -n "➜ Creando acceso directo permanente... "

# Función para añadir el alias si no existe
add_alias() {
    local config_file=$1
    if [ -f "$config_file" ]; then
        if ! grep -q "alias jakiscanner=" "$config_file"; then
            echo "alias jakiscanner='python3 /usr/local/bin/jakiscanner'" >> "$config_file"
        fi
    fi
}

# Aplicar a Bash y ZSH (los dos que usa Kali)
add_alias "$USER_HOME/.bashrc"
add_alias "$USER_HOME/.zshrc"

echo -e "${GREEN}[OK]${NC}"



# 6. Finalización
echo -e "\n${BOLD}${GREEN}¡INSTALACIÓN COMPLETADA CON ÉXITO!${NC}"
echo -e "${CYAN}------------------------------------------${NC}"
echo -e "Para activar el comando AHORA, ejecuta:"
echo -e "${BOLD}source ~/.bashrc && source ~/.zshrc 2>/dev/null${NC}"
echo -e "O simplemente abre una nueva terminal."
echo -e "${CYAN}------------------------------------------${NC}"
