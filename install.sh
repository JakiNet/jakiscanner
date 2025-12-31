#!/bin/bash

# --- Colores ---
CYAN='\033[0;36m'
GREEN='\033[0;32m'
NC='\033[0m'

# 1. Validar Root
if [ "$EUID" -ne 0 ]; then 
  echo -e "\033[0;31m[!] Ejecuta con sudo: sudo ./install.sh\033[0m"
  exit 1
fi

# 2. Crear carpeta en /opt (Como en JakiSnippets)
mkdir -p /opt/jakiscanner

# 3. Copiar el archivo manteniendo su extensión en /opt
cp -f jakiscanner.py /opt/jakiscanner/jakiscanner.py
chmod +x /opt/jakiscanner/jakiscanner.py

# 4. CREAR EL COMANDO LIMPIO (Sin .py)
# Esto vincula 'jakiscanner' con el archivo real
ln -sf /opt/jakiscanner/jakiscanner.py /usr/local/bin/jakiscanner

# 5. Dependencias
apt-get update -y > /dev/null 2>&1
apt-get install -y python3-tqdm > /dev/null 2>&1

echo -e "${GREEN}✔ Instalación completa. Escribe 'jakiscanner' para empezar.${NC}"
