#!/bin/bash

# --- Colores ---
CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'
BOLD='\033[1m'

# 1. Validar Root para la INSTALACIÓN (solo para mover archivos)
if [ "$EUID" -ne 0 ]; then 
  echo -e "${RED}${BOLD}[!] Usa sudo solo para INSTALAR: sudo ./install.sh${NC}"
  exit 1
fi

# Detectar usuario real
REAL_USER=$SUDO_USER
USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

clear
echo -e "${CYAN}=========================================="
echo -e "    INSTALADOR JAKISCANNER (MODO USUARIO)  "
echo -e "==========================================${NC}\n"

# 2. Dependencias (Instalación global para que todos tengan acceso)
echo -n "➜ Configurando librerías... "
apt-get update -y > /dev/null 2>&1
apt-get install -y python3-tqdm > /dev/null 2>&1
echo -e "${GREEN}[OK]${NC}"

# 3. Copiar y dar permisos UNIVERSALES
echo -n "➜ Configurando permisos de ejecución... "
SOURCE=$(ls jakiscanner* | grep -v "install.sh" | head -n 1)
cp "$SOURCE" /usr/local/bin/jakiscanner

# AQUÍ ESTÁ EL TRUCO: 
# 755 significa: Propietario puede todo, el resto puede leer y EJECUTAR.
chmod 755 /usr/local/bin/jakiscanner 
# Cambiamos el dueño al usuario real para que no haya bloqueos
chown $REAL_USER:$REAL_USER /usr/local/bin/jakiscanner 
echo -e "${GREEN}[OK]${NC}"

# 4. Crear el Alias sin la palabra 'sudo'
echo -n "➜ Creando acceso directo... "
add_alias() {
    local config_file=$1
    if [ -f "$config_file" ]; then
        # Eliminamos alias viejos si existen para evitar basura
        sed -i '/alias jakiscanner=/d' "$config_file"
        # Añadimos el nuevo alias limpio
        echo "alias jakiscanner='python3 /usr/local/bin/jakiscanner'" >> "$config_file"
        chown $REAL_USER:$REAL_USER "$config_file"
    fi
}

add_alias "$USER_HOME/.bashrc"
add_alias "$USER_HOME/.zshrc"
echo -e "${GREEN}[OK]${NC}"

echo -e "\n${BOLD}${GREEN}¡LISTO! Instalación terminada.${NC}"
echo -e "Cierra esta terminal y abre una nueva (o escribe 'source ~/.zshrc')."
echo -e "Ahora solo escribe: ${CYAN}jakiscanner${NC}"
