

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




## 🤖 Configurar alertas por ping a Telegram

### 1. Crear bot en Telegram
1. Abre Telegram y busca `@BotFather`
2. Envía: `/newbot`
3. Nombre: `ZabbixAlertas`
4. Username: `zabbix_alertas_bot` (debe terminar en `bot`)
5. **Guarda el token** (ejemplo: `1234567890:ABCdefGHIjklmNOPqrstUVwxyz`)

### 2. Obtener tu Chat ID
1. Envía un mensaje a tu bot: `Hola`
2. Abre en navegador: `https://api.telegram.org/botTU_TOKEN/getUpdates`
3. Busca `"id":` (ejemplo: `1254708547`)

### 3. Configurar script en el servidor
```bash
mkdir -p /usr/lib/zabbix/alertscripts

cat > /usr/lib/zabbix/alertscripts/telegram_bot.sh << 'EOF'
#!/bin/bash
TOKEN="TU_TOKEN_AQUI"
CHAT_ID="TU_CHAT_ID_AQUI"
MENSAJE="$1"

/usr/bin/curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" \
    -d "chat_id=$CHAT_ID" \
    -d "text=$MENSAJE" \
    -d "parse_mode=HTML"
EOF

chmod 755 /usr/lib/zabbix/alertscripts/telegram_bot.sh
chown zabbix:zabbix /usr/lib/zabbix/alertscripts/telegram_bot.sh

/usr/lib/zabbix/alertscripts/telegram_bot.sh "✅ PRUEBA: Zabbix conectado a Telegram"
```


### 4. Configurar Zabbix Web

#### 4.1. Crear Media Type
**Alerts → Media types → Create media type**

| Campo | Valor |
|-------|-------|
| Name | `Telegram Bot` |
| Type | `Script` |
| Script name | `telegram_bot.sh` |
| Script parameters | `{ALERT.MESSAGE}` |

#### 4.2. Asignar medio al usuario Admin
**Administration → Users → Admin → Media → Add**

| Campo | Valor |
|-------|-------|
| Type | `Telegram Bot` |
| Send to | `telegram` |
| When active | `1-7,00:00-24:00` |

#### 4.3. Crear grupos de hosts
**Configuration → Host groups → Create host group**
- `Servidores Críticos`
- `Servidores No Críticos`

### 5. Configurar plantillas de monitoreo por ping

#### 5.1. Clonar plantilla ICMP Ping
**Configuration → Templates** → `Template ICMP Ping` → **Full clone**

| Clon | Template name |
|------|---------------|
| Crítico | `ICMP Ping - Critico` |
| No Crítico | `ICMP Ping - No Critico` |

#### 5.2. Configurar plantilla CRÍTICO (alerta inmediata)
**Items:** `ICMP ping` → **Update interval:** `5s`

**Triggers:** Editar `ICMP Ping: Unavailable by ICMP ping`
- **Expression:** `max(/ICMP Ping - Critico/icmpping,#1)=0`
- **Severity:** `High`
- Desactivar los otros dos triggers

#### 5.3. Configurar plantilla NO CRÍTICO (alerta en ~1 minuto)
**Items:** `ICMP ping` → **Update interval:** `1m` (no modificar)

**Triggers:** Editar `ICMP Ping: Unavailable by ICMP ping`
- **Expression:** `max(/ICMP Ping - No Critico/icmpping,#1)=0`
- **Severity:** `High`
- Desactivar los otros dos triggers

### 6. Crear acciones

#### Acción 1: Críticos
**Alerts → Actions → Create action**
- **Name:** `Alerta Telegram - Críticos`
- **Conditions:** `Host group` = `Servidores Críticos`
- **Operations:** Send to `Admin` via `Telegram Bot`
- **Custom message:** `🔴 ALERTA INMEDIATA: {HOST.NAME} ({HOST.IP}) no responde al ping`

#### Acción 2: No Críticos
**Alerts → Actions → Create action**
- **Name:** `Alerta Telegram - No Críticos`
- **Conditions:** `Host group` = `Servidores No Críticos`
- **Operations:** Send to `Admin` via `Telegram Bot`
- **Custom message:** `⚠️ ALERTA (1 min caído): {HOST.NAME} ({HOST.IP}) no responde al ping`

### 7. Probar con hosts de ejemplo

#### Host Crítico
**Configuration → Hosts → Create host**

| Campo | Valor |
|-------|-------|
| Name | `Test-Critico` |
| Groups | `Servidores Críticos` |
| IP | `10.255.255.254` |
| Templates | `ICMP Ping - Critico` |

**Tiempo estimado:** 1-5 segundos

#### Host No Crítico
**Configuration → Hosts → Create host**

| Campo | Valor |
|-------|-------|
| Name | `Test-NoCritico` |
| Groups | `Servidores No Críticos` |
| IP | `10.255.255.253` |
| Templates | `ICMP Ping - No Critico` |

**Tiempo estimado:** 40-60 segundos

### 8. Resultados esperados

| Tipo | Mensaje en Telegram | Tiempo |
|------|---------------------|--------|
| Crítico | 🔴 ALERTA INMEDIATA: Test-Critico (10.255.255.254) no responde al ping | 1-5 segundos |
| No Crítico | ⚠️ ALERTA (1 min caído): Test-NoCritico (10.255.255.253) no responde al ping | 40-60 segundos |

### 9. Resumen de configuración

| Plantilla | Item intervalo | Trigger | Severidad | Tiempo |
|-----------|---------------|---------|-----------|--------|
| **Crítico** | `5s` | `#1=0` | `High` | 1-5 segundos |
| **No Crítico** | `1m` | `#1=0` | `High` | 40-60 segundos |

## 🛠️ Comandos útiles para diagnóstico

```bash
# Ver log de Zabbix
tail -f /var/log/zabbix/zabbix_server.log

# Probar script manualmente
/usr/lib/zabbix/alertscripts/telegram_bot.sh "Prueba manual"

# Verificar conexión a base de datos
grep "^DBUser\|^DBPassword" /etc/zabbix/zabbix_server.conf
mysql -u zabbix -p'zabbixPassword123' -e "SELECT 1"

# Reiniciar Zabbix
systemctl restart zabbix-server
```



Autor
Carlos Silva
GitHub: @Carlos-Silva-Sys



