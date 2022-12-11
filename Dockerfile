FROM python:3.9-slim-bullseye

RUN apt update \
 && apt install -y \
      python3-cryptography \
      python3-gevent \
      python3-opencv \
      x264 \
      libx264-dev \
      libwebp-dev \
 && apt clean \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /opt

RUN groupadd moonraker-telegram-bot --gid 1000 \
 && useradd moonraker-telegram-bot --uid 1000 --gid moonraker-telegram-bot \
 && mkdir -p printer_data/logs printer_data/config timelapse timelapse_finished \
 && chown -R moonraker-telegram-bot:moonraker-telegram-bot /opt/*

COPY --chown=moonraker-telegram-bot:moonraker-telegram-bot . ./moonraker-telegram-bot
RUN python3 -m venv venv \
 && venv/bin/pip install -r moonraker-telegram-bot/scripts/requirements.txt

USER moonraker-telegram-bot
VOLUME [ "/opt/printer_data/logs", "/opt/printer_data/config", "/opt/timelapse","/opt/timelapse_finished"]
ENTRYPOINT ["/opt/venv/bin/python3", "moonraker-telegram-bot/bot/main.py"]
CMD ["-c", "/opt/printer_data/config/telegram.conf", "-l", "/opt/printer_data/logs"]