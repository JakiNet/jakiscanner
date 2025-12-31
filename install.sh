#!/bin/bash

# --- Configuración de Estética ---
CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'
BOLD='\033[1m'

# 1. Comprobación de privilegios para la instalación
if [ "$EUID" -ne 0 ]; then 
  echo -e "${RED}${BOLD}[!] Error: Para instalar, usa: sudo ./install.sh${NC}"
  exit 1
fi

clear
echo -e "${CYAN}${BOLD}=========================================="
echo -e "         INSTALADOR DE JAKISCANNER        "
echo -e "==========================================${NC}"

# 2. Instalación de dependencias (tqdm)
echo -e "\n${CYAN}➜${NC} Configurando entorno y dependencias..."
apt-get update -y > /dev/null 2>&1
apt-get install -y python3-tqdm > /dev/null 2>&1
# Fallback por si apt falla
pip3 install tqdm --break-system-packages --user > /dev/null 2>&1

# 3. Localizar y preparar el archivo
SOURCE=$(ls jakiscanner* | grep -v "install.sh" | head -n 1)

# 4. Instalación Global
echo -e "${CYAN}➜${NC} Registrando comando en el sistema..."
cp "$SOURCE" /usr/local/bin/jakiscanner

# Configuración de permisos: Propietario jaki (si existe), ejecutable por TODOS
if id "jaki" &>/dev/null; then
    chown jaki:jaki /usr/local/bin/jakiscanner
else
    chown root:root /usr/local/bin/jakiscanner
fi
chmod 755 /usr/local/bin/jakiscanner

# Crear enlace simbólico para asegurar disponibilidad inmediata
ln -sf /usr/local/bin/jakiscanner /usr/bin/jakiscanner

# 5. Mensaje Final Limpio
echo -e "\n${GREEN}${BOLD}¡INSTALACIÓN COMPLETADA CON ÉXITO!${NC}"
echo -e "${CYAN}------------------------------------------${NC}"
echo -e "Ya puedes usar la herramienta escribiendo:"
echo -e "${BOLD}${WHITE}jakiscanner${NC}"
echo -e "${CYAN}------------------------------------------${NC}"
echo -e "${CYAN}Nota:${NC} Si el comando no se reconoce al instante,"
echo -e "abre una nueva pestaña en tu terminal."
