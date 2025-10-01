#!/bin/bash
set -euxo pipefail

echo "[MONITOR] Déploiement de la stack Prometheus + Grafana + Alertmanager + Postfix"

# === PRÉREQUIS ===
apt update
apt install -y wget curl gnupg mailutils

# === VARIABLES ===
PROM_VERSION="2.52.0"
ALERTMANAGER_VERSION="0.27.0"
NODE_EXPORTER_VERSION="1.8.1"
GRAFANA_DEB_URL="https://dl.grafana.com/oss/release/grafana_10.4.2_amd64.deb"

# === 1. Node Exporter (sur monitor aussi) ===
echo "[MONITOR] Installation de Node Exporter"
useradd --no-create-home --shell /usr/sbin/nologin node_exporter || true
cd /tmp
wget https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz
tar -xzf node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz
cp node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64/node_exporter /usr/local/bin/
chown node_exporter:node_exporter /usr/local/bin/node_exporter

cat <<EOF > /etc/systemd/system/node_exporter.service
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=node_exporter
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reexec
systemctl daemon-reload
systemctl enable --now node_exporter

# === 2. Prometheus ===
echo "[MONITOR] Installation de Prometheus"
useradd --no-create-home --shell /usr/sbin/nologin prometheus || true
mkdir -p /etc/prometheus /var/lib/prometheus

cd /tmp
wget https://github.com/prometheus/prometheus/releases/download/v${PROM_VERSION}/prometheus-${PROM_VERSION}.linux-amd64.tar.gz
tar -xzf prometheus-${PROM_VERSION}.linux-amd64.tar.gz
cd prometheus-${PROM_VERSION}.linux-amd64
cp prometheus promtool /usr/local/bin/
cp -r consoles console_libraries /etc/prometheus/
cp /vagrant/scripts/prometheus.yml /etc/prometheus/prometheus.yml
cp /vagrant/scripts/alerts.yml /etc/prometheus/alerts.yml
chown -R prometheus:prometheus /etc/prometheus /var/lib/prometheus

cat <<EOF > /etc/systemd/system/prometheus.service
[Unit]
Description=Prometheus Monitoring
After=network.target

[Service]
User=prometheus
ExecStart=/usr/local/bin/prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/var/lib/prometheus \
  --web.console.templates=/etc/prometheus/consoles \
  --web.console.libraries=/etc/prometheus/console_libraries

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now prometheus

# === 3. Alertmanager ===
echo "[MONITOR] Installation d'Alertmanager"
useradd --no-create-home --shell /usr/sbin/nologin alertmanager || true
mkdir -p /etc/alertmanager /var/lib/alertmanager

cd /tmp
wget https://github.com/prometheus/alertmanager/releases/download/v${ALERTMANAGER_VERSION}/alertmanager-${ALERTMANAGER_VERSION}.linux-amd64.tar.gz
tar -xzf alertmanager-${ALERTMANAGER_VERSION}.linux-amd64.tar.gz
cd alertmanager-${ALERTMANAGER_VERSION}.linux-amd64
cp alertmanager amtool /usr/local/bin/
cp /vagrant/scripts/alertmanager.yml /etc/alertmanager/
chown -R alertmanager:alertmanager /etc/alertmanager /var/lib/alertmanager

cat <<EOF > /etc/systemd/system/alertmanager.service
[Unit]
Description=Prometheus Alertmanager
After=network.target

[Service]
User=alertmanager
ExecStart=/usr/local/bin/alertmanager \
  --config.file=/etc/alertmanager/alertmanager.yml \
  --storage.path=/var/lib/alertmanager

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now alertmanager

# === 4. Grafana ===
echo "[MONITOR] Installation de Grafana"
cd /tmp
wget ${GRAFANA_DEB_URL}
dpkg -i grafana_10.4.2_amd64.deb || true
apt install -f -y
mkdir -p /etc/grafana/provisioning/datasources
cp /vagrant/scripts/datasource.yml /etc/grafana/provisioning/datasources/
systemctl enable --now grafana-server

# === 5. Postfix (Internet Site, envoi uniquement) ===
echo "[MONITOR] Installation de Postfix (envoi uniquement)"
debconf-set-selections <<< "postfix postfix/mailname string monitor.mediaschool.local"
debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"
apt install -y postfix

# Remplacer le fichier main.cf par celui fourni
cp /vagrant/scripts/postfix_main.cf /etc/postfix/main.cf
systemctl restart postfix

# === Nettoyage (optionnel) ===
rm -rf /tmp/*.tar.gz /tmp/*linux-amd64 /tmp/grafana_*.deb

echo "[MONITOR] Stack complète installée et configurée avec succès ✅"
