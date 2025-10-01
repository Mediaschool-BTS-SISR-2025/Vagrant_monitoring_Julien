#!/bin/bash
set -e

echo "[COMMON] Mise à jour du système et installation de paquets de base"

# Mise à jour du système
apt update && apt upgrade -y

# Installations de base
apt install -y curl wget ufw unzip gnupg2 lsb-release software-properties-common net-tools vim

# Installation de chrony pour la synchro NTP
apt install -y chrony
systemctl enable chrony --now

# Configuration des noms d'hôtes statiques
echo "[COMMON] Configuration des hosts"

cat <<EOF >> /etc/hosts
192.168.56.10 monitor.mediaschool.local monitor
192.168.56.200 node1.mediaschool.local node1
EOF
