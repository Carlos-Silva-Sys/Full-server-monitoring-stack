# Zabbix + Grafana - Instalación Todo-en-Uno

Script automatizado para instalar Zabbix 7.0 LTS y Grafana en una sola máquina virtual con Debian 12.

---

## 📋 Descripción

**Problema que resuelve:**  
Las instalaciones tradicionales requieren 2 servidores separados (Zabbix en uno, Grafana en otro), duplicando recursos.

**Solución:**  
Este script instala y configura ambos servicios en una sola máquina virtual Debian 12, reduciendo el consumo de CPU, RAM y disco a la mitad.

---

## 🚀 Tecnologías

| Tecnología | Versión | Puerto |
|------------|---------|--------|
| Zabbix Server | 7.0 LTS | 80 / 10051 |
| Grafana | Latest (OSS) | 3000 |
| MariaDB | 10.x | - |
| Debian | 12 (Bookworm) | - |

---

## ⚙️ Instalación

### 1. Crear el script

```bash
nano install.sh
