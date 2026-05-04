

# Zabbix + Grafana - Instalación Todo-en-Uno

Script automatizado para instalar Zabbix 7.0 LTS y Grafana en una sola máquina virtual con Debian 12.

---

## ⚠️ IMPORTANTE - ANTES DE EJECUTAR

**Debes editar el script y cambiar la siguiente contraseña por una segura:**

`DB_PASSWORD="CAMBIAR_A_CONTRASEÑA_SEGURA"`

Si no cambias esta contraseña, el script no se ejecutará.

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

Crear Archivo:
nano install-zabbix-grafana.sh

Permisos:
chmod +x install-zabbix-grafana.sh

Ejecucion:
sudo ./install-zabbix-grafana.sh


```

4. Acceder

| Servicio | URL | Usuario | Contraseña |
|----------|-----|---------|------------|
| Zabbix | http://TU-IP/zabbix | Admin | zabbix |
| Grafana | http://TU-IP:3000 | admin | admin |



## 🔧 Pasos después de ejecutar el script

Una vez que el script termina correctamente, sigue estos pasos:

### 1. Cambiar contraseña de Zabbix

1. Abre: `http://TU-IP/zabbix`
2. Usuario: `Admin` | Contraseña: `zabbix`
3. Ve a **Administration → Users**
4. Haz clic en **Admin** → **Change password**
5. Asigna una contraseña segura
6. Guarda los cambios

### 2. Cambiar contraseña de Grafana

1. Abre: `http://TU-IP:3000`
2. Usuario: `admin` | Contraseña: `admin`
3. El sistema te pedirá cambiar la contraseña inmediatamente
4. Asigna una contraseña segura

### 3. Integrar Grafana con Zabbix

1. En Grafana, ve a **Configuration (rueda dentada) → Data sources → Add data source**
2. Busca **Zabbix** y selecciónalo
3. Configura:
   - **URL**: `http://localhost/zabbix/api_jsonrpc.php`
   - **Username**: `Admin`
   - **Password**: (la que asignaste en Zabbix)
4. Haz clic en **Save & Test**
5. Debe aparecer: `Zabbix API version: 6.0` ✅

### 4. Verificar servicios

```bash

systemctl status zabbix-server
systemctl status grafana-server
systemctl status mariadb

```


Autor
Carlos Silva
GitHub: @Carlos-Silva-Sys



