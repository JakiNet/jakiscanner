#!/bin/bash

# --- Colores ---
CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'
BOLD='\033[1m'

# 1. Validar Root
if [ "$EUID" -ne 0 ]; then 
  echo -e "${RED}${BOLD}[!] Error: Se requiere sudo.${NC}"
  exit 1
fi

clear
echo -e "${CYAN}=========================================="
echo -e "    INSTALADOR UNIVERSAL: JAKISCANNER     "
echo -e "==========================================${NC}\n"

# 2. Instalar tqdm (de la forma más segura en Kali)
echo -n "➜ Configurando dependencias... "
apt-get update -y > /dev/null 2>&1
apt-get install -y python3-tqdm > /dev/null 2>&1
pip3 install tqdm --break-system-packages --user > /dev/null 2>&1
echo -e "${GREEN}[OK]${NC}"

# 3. Localizar el script original
# Buscamos jakiscanner o jakiscanner.py
SOURCE=$(ls jakiscanner* | grep -v "install.sh" | head -n 1)

# 4. Registro Global
echo -n "➜ Instalando '$SOURCE' como comando... "
cp "$SOURCE" /usr/local/bin/jakiscanner
chmod +x /usr/local/bin/jakiscanner
# Crear enlace en /usr/bin (esto asegura que casi cualquier PATH lo vea)
ln -sf /usr/local/bin/jakiscanner /usr/bin/jakiscanner
echo -e "${GREEN}[OK]${NC}"

# 5. Forzar actualización de la terminal actual
echo -n "➜ Actualizando caché de comandos... "
hash -r 2>/dev/null || rehash 2>/dev/null
echo -e "${GREEN}[OK]${NC}"

echo -e "\n${BOLD}${GREEN}¡TODO LISTO!${NC}"
echo -e "${CYAN}------------------------------------------${NC}"
echo -e "Prueba el comando ahora mismo con:"
echo -e "${BOLD}jakiscanner${NC}"
echo -e "${CYAN}------------------------------------------${NC}"
echo -e "Nota: Si falla, simplemente abre una nueva pestaña."
