


#!/bin/bash
# =====================================================
#  INFLUXDB V2 - INSTALACIÓN PARA ZABBIX + GRAFANA
#  VERSIÓN DEFINITIVA (probada y funcionando)
# =====================================================

IP_SERVIDOR=$(hostname -I | awk '{print $1}')

echo "=== 1. CORRIGIENDO HORA DEL SISTEMA ==="
apt update
apt install -y systemd-timesyncd
timedatectl set-ntp true
timedatectl set-timezone America/Caracas
systemctl restart systemd-timesyncd
sleep 2
timedatectl

echo ""
echo "=== 2. INSTALANDO INFLUXDB V2 ==="
curl -sL https://repos.influxdata.com/influxdata-archive.key | apt-key add -
echo "deb https://repos.influxdata.com/debian stable main" > /etc/apt/sources.list.d/influxdata.list
apt update
apt install -y influxdb2

echo ""
echo "=== 3. INICIANDO SERVICIO ==="
systemctl start influxdb
systemctl enable influxdb
sleep 3

echo ""
echo "=== 4. ABRIENDO PUERTO EN FIREWALL ==="
ufw allow 8086/tcp
ufw reload

echo ""
echo "=== 5. VERIFICANDO ==="
if curl -s http://localhost:8086/health > /dev/null; then
    echo "✅ InfluxDB responde correctamente"
else
    echo "❌ Error: InfluxDB no responde"
    exit 1
fi

echo ""
echo "=========================================="
echo "✅ INFLUXDB V2 INSTALADO CORRECTAMENTE"
echo "=========================================="
echo ""
echo "🌐 INTERFAZ WEB: http://${IP_SERVIDOR}:8086"
echo ""
echo "📝 PRIMERA CONFIGURACIÓN:"
echo "   Username: admin"
echo "   Contraseña: admin123"
echo "   Organización: monitoreo"
echo "   Bucket: proxmox"
echo ""
echo "⚠️  GUARDA EL TOKEN QUE APARECE AL FINAL"
echo "=========================================="





