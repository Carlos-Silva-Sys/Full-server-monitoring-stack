#!/bin/bash
# ======================================================
#  ZABBIX 7.0 LTS + GRAFANA - STANDALONE INSTALLER
#  PARA DEBIAN 12 (BOOKWORM)
# ======================================================
#  ⚠️ CAMBIA LA SIGUIENTE CONTRASEÑA ANTES DE EJECUTAR
# ======================================================

DB_USER="zabbixservidores"
DB_PASSWORD="CAMBIAR_A_CONTRASEÑA_SEGURA"   # <--- ¡CÁMBIALA!
DB_NAME="zabbix"
SERVER_IP=$(hostname -I | awk '{print $1}')

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== INSTALANDO ZABBIX + GRAFANA ===${NC}"

# ============================================
# 1. CONFIGURAR LOCALES
# ============================================
echo -e "${YELLOW}🌍 Configurando idioma...${NC}"
apt update
apt install -y locales

cat > /etc/locale.gen <<EOF
en_US.UTF-8 UTF-8
es_VE.UTF-8 UTF-8
EOF

locale-gen

cat > /etc/default/locale <<EOF
LANG=en_US.UTF-8
LANGUAGE=en_US:en
LC_ALL=en_US.UTF-8
LC_CTYPE=en_US.UTF-8
EOF

export LANG=en_US.UTF-8
export LANGUAGE=en_US:en
export LC_ALL=en_US.UTF-8
export LC_CTYPE=en_US.UTF-8

# ============================================
# 2. INSTALAR PAQUETES BÁSICOS
# ============================================
echo -e "${YELLOW}📦 Instalando paquetes básicos...${NC}"
apt install -y wget gnupg2 curl mariadb-server mariadb-client ufw

# ============================================
# 3. CREAR BASE DE DATOS
# ============================================
echo -e "${YELLOW}🗄️ Creando base de datos...${NC}"
mysql -u root <<EOF
CREATE DATABASE IF NOT EXISTS ${DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;
CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';
FLUSH PRIVILEGES;
EOF

# ============================================
# 4. INSTALAR ZABBIX
# ============================================
echo -e "${YELLOW}📥 Instalando Zabbix 7.0...${NC}"
wget -q https://repo.zabbix.com/zabbix/7.0/debian/pool/main/z/zabbix-release/zabbix-release_7.0-1+debian12_all.deb
dpkg -i zabbix-release_7.0-1+debian12_all.deb
apt update
apt install -y zabbix-server-mysql zabbix-frontend-php zabbix-apache-conf zabbix-sql-scripts zabbix-agent

# Importar esquema
echo -e "${YELLOW}📊 Importando esquema...${NC}"
zcat /usr/share/zabbix-sql-scripts/mysql/server.sql.gz | mysql -u ${DB_USER} -p${DB_PASSWORD} ${DB_NAME}

# Configurar Zabbix Server
sed -i "s/# DBPassword=/DBPassword=${DB_PASSWORD}/" /etc/zabbix/zabbix_server.conf

# Configurar PHP
PHP_INI=$(find /etc/php -name "php.ini" -path "*/apache2/*" | head -1)
if [ -n "$PHP_INI" ]; then
    sed -i "s/^date.timezone =.*/date.timezone = America\/Caracas/" $PHP_INI
    if ! grep -q "date.timezone" $PHP_INI; then
        echo "date.timezone = America/Caracas" >> $PHP_INI
    fi
fi

# Iniciar servicios Zabbix
systemctl restart mariadb zabbix-server zabbix-agent apache2
systemctl enable mariadb zabbix-server zabbix-agent apache2

# ============================================
# 5. INSTALAR GRAFANA
# ============================================
echo -e "${YELLOW}📈 Instalando Grafana...${NC}"
apt install -y software-properties-common

wget -q -O /usr/share/keyrings/grafana.key https://packages.grafana.com/gpg.key
echo "deb [signed-by=/usr/share/keyrings/grafana.key] https://packages.grafana.com/oss/deb stable main" > /etc/apt/sources.list.d/grafana.list

apt update
apt install -y grafana

systemctl daemon-reload
systemctl enable grafana-server
systemctl start grafana-server

echo -e "${YELLOW}⏳ Esperando a que Grafana inicie...${NC}"
sleep 10

# Instalar plugin de Zabbix
echo -e "${YELLOW}🔌 Instalando plugin Zabbix para Grafana...${NC}"
grafana-cli plugins install alexanderzobnin-zabbix-app

chown -R grafana:grafana /var/lib/grafana/plugins/
systemctl restart grafana-server

# ============================================
# 6. CONFIGURAR FIREWALL
# ============================================
echo -e "${YELLOW}🔥 Configurando firewall (UFW)...${NC}"
ufw allow 22/tcp comment 'SSH'
ufw allow 80/tcp comment 'HTTP (Zabbix)'
ufw allow 443/tcp comment 'HTTPS'
ufw allow 3000/tcp comment 'Grafana'
ufw allow 10051/tcp comment 'Zabbix Server'
echo "y" | ufw enable

# ============================================
# 7. LIMPIEZA
# ============================================
rm -f zabbix-release_7.0-1+debian12_all.deb

# ============================================
# 8. RESULTADO FINAL
# ============================================
echo -e "\n${GREEN}=========================================="
echo "✅ INSTALACIÓN COMPLETADA EXITOSAMENTE"
echo "==========================================${NC}"

echo -e "${YELLOW}📊 Estado de servicios:${NC}"
for service in mariadb zabbix-server apache2 grafana-server; do
    if systemctl is-active --quiet $service; then
        echo -e "  ${GREEN}✅ $service: Activo${NC}"
    else
        echo -e "  ${RED}❌ $service: Inactivo${NC}"
    fi
done

echo -e "\n${GREEN}🌐 ACCESOS:${NC}"
echo "  🔵 ZABBIX : http://${SERVER_IP}/zabbix"
echo "     Usuario: Admin | Contraseña: zabbix"
echo ""
echo "  🟠 GRAFANA: http://${SERVER_IP}:3000"
echo "     Usuario: admin | Contraseña: admin"
echo ""
echo "  🗄️ Base de Datos: ${DB_USER} / ${DB_PASSWORD}"

if [ -d "/var/lib/grafana/plugins/alexanderzobnin-zabbix-app" ]; then
    echo -e "\n${GREEN}✅ Plugin Zabbix para Grafana instalado correctamente${NC}"
else
    echo -e "\n${YELLOW}⚠️ Plugin no encontrado. Instalación manual:${NC}"
    echo "   sudo grafana-cli plugins install alexanderzobnin-zabbix-app"
    echo "   sudo systemctl restart grafana-server"
fi

echo -e "\n${GREEN}==========================================${NC}"
echo -e "${YELLOW}🔐 RECUERDA CAMBIAR LA CONTRASEÑA DE GRAFANA y ZABBIX en el primer inicio${NC}"
