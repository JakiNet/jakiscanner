#!/bin/bash

# Colores para la terminal
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 1. Obtener la ruta real de donde se está ejecutando el instalador
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
INSTALL_DIR="/opt/jakiscanner"

echo -e "${GREEN}--- Iniciando instalación de JakiScanner ---${NC}"

# 2. Verificar si se ejecuta como root
if [ "$EUID" -ne 0 ]; then 
  echo -e "${RED}[!] Error: Por favor, ejecuta como root (sudo ./install.sh)${NC}"
  exit 1
fi

# 3. Crear el directorio si no existe
mkdir -p $INSTALL_DIR

# 4. Copiar el archivo verificando su existencia
if [ -f "$SCRIPT_DIR/jakiscanner.py" ]; then
    cp "$SCRIPT_DIR/jakiscanner.py" "$INSTALL_DIR/"
    echo -e "${GREEN}[*] Archivos copiados a $INSTALL_DIR ... HECHO${NC}"
else
    echo -e "${RED}[!] Error: No se encontró 'jakiscanner.py' en $SCRIPT_DIR${NC}"
    exit 1
fi

# 5. Dar permisos de ejecución
chmod +x "$INSTALL_DIR/jakiscanner.py"

# 6. Crear el enlace simbólico para que el comando funcione globalmente
# Eliminamos el anterior si existe para evitar errores
rm -f /usr/local/bin/jakiscanner
ln -s "$INSTALL_DIR/jakiscanner.py" /usr/local/bin/jakiscanner

if [ -L /usr/local/bin/jakiscanner ]; then
    echo -e "${GREEN}[*] Enlace simbólico creado ... HECHO${NC}"
else
    echo -e "${RED}[!] Error al crear el comando global${NC}"
    exit 1
fi

echo -e "\n${GREEN}¡CONFIGURACIÓN FINALIZADA!${NC}"
echo -e "Ya puedes usar el comando: ${GREEN}jakiscanner${NC}"
