#!/bin/bash

set -e

# Prompt for user
read -rp "Enter FTP username: " FTP_USER

# Ask if it's a system user
read -rp "Is this a system user? (y/n): " IS_SYSTEM

# Install vsftpd and UFW if not installed
apt update
apt install -y vsftpd ufw

# Configure user and home directory
if [[ "$IS_SYSTEM" == "y" || "$IS_SYSTEM" == "Y" ]]; then
    if id "$FTP_USER" &>/dev/null; then
        echo "User $FTP_USER already exists."
    else
        adduser "$FTP_USER"
    fi
    FTP_HOME="/home/$FTP_USER"
else
    FTP_HOME="/srv/ftp/$FTP_USER"
    mkdir -p "$FTP_HOME"
    useradd -d "$FTP_HOME" -s /usr/sbin/nologin "$FTP_USER"
    passwd "$FTP_USER"
    chown nobody:nogroup "$FTP_HOME"
    chmod a-w "$FTP_HOME"
    mkdir -p "$FTP_HOME/files"
    chown "$FTP_USER":"$FTP_USER" "$FTP_HOME/files"
fi

# Configure vsftpd
cat <<'VSFTEOF' > /etc/vsftpd.conf
listen=YES
anonymous_enable=NO
local_enable=YES
write_enable=YES
local_umask=022
chroot_local_user=YES
allow_writeable_chroot=YES
user_sub_token=$USER
local_root=/home/$USER
pasv_enable=YES
pasv_min_port=10000
pasv_max_port=10100
VSFTEOF

# Open firewall ports for FTP
ufw allow 20/tcp
ufw allow 21/tcp
ufw allow 10000:10100/tcp
ufw reload

# Enable and restart vsftpd
systemctl enable vsftpd
systemctl restart vsftpd

echo
if [[ "$IS_SYSTEM" == "y" || "$IS_SYSTEM" == "Y" ]]; then
    echo "FTP setup complete. $FTP_USER can log in with their system credentials and home directory."
else
    echo "FTP-only user $FTP_USER has been set up with isolated access to: $FTP_HOME/files"
fi
