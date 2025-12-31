# JakiScanner v1.0

**JakiScanner** es una herramienta de reconocimiento de red ligera y potente diseñada para entornos de pruebas de penetración. A diferencia de los escáneres convencionales, optimiza la velocidad mediante hilos concurrentes y proporciona inteligencia sobre el objetivo de forma inmediata.



## 🛠️ ¿Por qué usar JakiScanner?

- **Detección Pasiva de OS:** Utiliza el análisis del valor **TTL (Time To Live)** en las respuestas ICMP para identificar si el objetivo es Linux o Windows antes de iniciar el escaneo.
- **Velocidad Extrema:** Arquitectura multihilo capaz de procesar cientos de puertos por segundo.
- **Banner Grabbing:** No solo detecta puertos abiertos, intenta identificar el servicio y la versión que se está ejecutando.
- **Salida Multiformato:** Genera reportes detallados en `.txt` para lectura humana o en `.json` para integración con otras herramientas.

## 📊 Especificaciones Técnicas

| Característica | Detalle |
| :--- | :--- |
| **Lenguaje** | Python 3.x |
| **Lógica** | TCP Connect (Full Handshake) |
| **Hilos** | Dinámicos (ajustables en código) |
| **Detección OS** | TTL: Linux (~64), Windows (~128) |

## 📥 Instalación

Clona el repositorio y ejecuta el instalador automático:

```bash
git clone [https://github.com/TuUsuario/JakiScanner.git](https://github.com/TuUsuario/JakiScanner.git)
cd JakiScanner
chmod +x install.sh
./install.sh
```
🚀 Uso Rápido

Simplemente escribe jakiscanner para entrar en el modo interactivo, o usa los argumentos:
bash
# Escaneo de una IP específica y guardado en txt
jakiscanner -t 192.168.1.1 -p 1-1000 -o reporte.txt
