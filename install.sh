#!/bin/bash
# This script installs Moonraker telegram bot
set -eu

SYSTEMDDIR="/etc/systemd/system"
MOONRAKER_BOT_ENV="${HOME}/moonraker-telegram-bot-env"
MOONRAKER_BOT_DIR="${HOME}/moonraker-telegram-bot"
KLIPPER_CONF_DIR="${HOME}/klipper_config"
CURRENT_USER=${USER}

stop_sevice() {
  serviceName="moonraker-telegram-bot"
  if sudo systemctl --all --type service | grep "$serviceName" | grep -q running; then
    ## stop existing instance
    echo "Stopping moonraker-telegram-bot instance ..."
    sudo systemctl stop moonraker-telegram-bot
  else
    echo "$serviceName service does not exist or not running."
  fi
}

cleanup_leagacy() {
  echo "Removing old packages"
  sudo apt remove --purge -y "python3-pil"
}

install_packages() {
  PKGLIST="python3-cryptography python3-gevent python3-opencv x264 libx264-dev libwebp-dev"
  sudo apt-get update --allow-releaseinfo-change
  sudo apt-get install --yes ${PKGLIST}
}

create_virtualenv() {
  mkdir -p "${HOME}"/space
  virtualenv -p /usr/bin/python3 --system-site-packages "${MOONRAKER_BOT_ENV}"
  export TMPDIR=${HOME}/space
  "${MOONRAKER_BOT_ENV}"/bin/pip install -r "${MOONRAKER_BOT_DIR}"/requirements.txt
}

create_service() {
  echo -e "\n\n\n"
  read -p "Enter your klipper configs path: " -e -i "${KLIPPER_CONF_DIR}" klip_conf_dir
  KLIPPER_CONF_DIR=${klip_conf_dir}
  echo -e "\nUsing configs from ${KLIPPER_CONF_DIR}\n"

  # check in config exists!
  # copy configfile if not exists
  if [[ -f "${KLIPPER_CONF_DIR}"/application.conf ]]; then
    mv "${KLIPPER_CONF_DIR}"/application.conf "${KLIPPER_CONF_DIR}"/telegram.conf
  fi

  cp -n "${MOONRAKER_BOT_DIR}"/docs/telegram_sample.conf "${KLIPPER_CONF_DIR}"/telegram.conf
  cp -rn "${MOONRAKER_BOT_DIR}"/imgs "${KLIPPER_CONF_DIR}"/

  ### create systemd service file
  sudo /bin/sh -c "cat > ${SYSTEMDDIR}/moonraker-telegram-bot.service" <<EOF
#Systemd service file for Moonraker Telegram Bot
[Unit]
Description=Starts Moonraker Telegram Bot on startup
After=network-online.target moonraker.service

[Install]
WantedBy=multi-user.target

[Service]
Type=simple
User=${CURRENT_USER}
ExecStart=${MOONRAKER_BOT_ENV}/bin/python ${MOONRAKER_BOT_DIR}/main.py -c ${KLIPPER_CONF_DIR}/telegram.conf
Restart=always
RestartSec=5
EOF

  ### enable instance
  sudo systemctl enable moonraker-telegram-bot.service
  echo "Single moonraker-telegram-bot instance created!"

  ### launching instance
  echo "Launching moonraker-telegram-bot instance ..."
  sudo systemctl start moonraker-telegram-bot
}

stop_sevice
cleanup_leagacy
install_packages
create_virtualenv
create_service
