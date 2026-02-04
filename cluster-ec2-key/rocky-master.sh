#!/bin/bash
set -e

# hostnamectl set-hostname master01.ocs.internal

useradd -m sge_admin
echo "sge_admin ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/sge_admin

mkdir -p /home/sge_admin/.ssh
cp /home/rocky/.ssh/authorized_keys /home/sge_admin/.ssh/
chown -R sge_admin:sge_admin /home/sge_admin/.ssh
chmod 600 /home/sge_admin/.ssh/authorized_keys

yum install -y wget tar java-17-openjdk

cd /opt
wget https://github.com/hpc-gridware/clusterscheduler/releases/latest/download/ocs-*-bin-lx-amd64.tar.gz
tar xzf ocs-*-bin-lx-amd64.tar.gz
chown -R sge_admin:sge_admin /opt/ocs

sudo -u sge_admin /opt/ocs/install_qmaster \
  -auto \
  -hostname master01.ocs.internal \
  -admin_user sge_admin \
  -execd_spool_dir /var/spool/ocs

mkdir -p /home/rocky/.ssh
chmod 700 /home/rocky/.ssh

chmod 600 /home/rocky/.ssh/id_rsa_ocs
chmod 644 /home/rocky/.ssh/id_rsa_ocs.pub

# Add public key to authorized_keys for passwordless SSH
cat /home/rocky/.ssh/id_rsa_ocs.pub >> /home/rocky/.ssh/authorized_keys
chmod 600 /home/rocky/.ssh/authorized_keys