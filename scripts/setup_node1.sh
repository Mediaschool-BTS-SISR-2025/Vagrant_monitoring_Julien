#!/bin/bash
set -e

echo "[NODE1] Installation de Node Exporter"

# Créer un utilisateur système pour Node Exporter
useradd --no-create-home --shell /usr/sbin/nologin node_exporter || true

# Télécharger et installer Node Exporter
cd /tmp
NODE_EXPORTER_VERSION="1.8.1"
wget https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz
tar -xzf node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz
cp node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64/node_exporter /usr/local/bin/
chown node_exporter:node_exporter /usr/local/bin/node_exporter

# Créer le service systemd
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

# Activer et démarrer Node Exporter
systemctl daemon-reload
systemctl enable --now node_exporter

echo "[NODE1] Node Exporter installé et en cours d'exécution"
