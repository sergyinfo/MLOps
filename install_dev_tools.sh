#!/bin/bash

LOG_FILE="install.log"

# Функція для логування
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "=== Початок налаштування середовища ==="

# Перевірка прав root
if [ "$EUID" -ne 0 ]; then
  log "ПОМИЛКА: Будь ласка, запустіть скрипт з sudo"
  exit 1
fi

# Оновлення списку пакетів
log "Оновлення apt cache..."
apt-get update -y >> "$LOG_FILE" 2>&1

# 1. Встановлення Docker
if command -v docker &> /dev/null; then
    log "Docker вже встановлено: $(docker --version)"
else
    log "Встановлення Docker..."
    apt-get install -y docker.io >> "$LOG_FILE" 2>&1
    systemctl start docker
    systemctl enable docker
    log "Docker успішно встановлено."
fi

# 2. Встановлення Docker Compose
if docker compose version &> /dev/null || command -v docker-compose &> /dev/null; then
    log "Docker Compose вже встановлено."
else
    log "Встановлення Docker Compose..."
    apt-get install -y docker-compose-plugin >> "$LOG_FILE" 2>&1 || apt-get install -y docker-compose >> "$LOG_FILE" 2>&1
    log "Docker Compose встановлено."
fi

# 3. Встановлення Python 3.9+ та pip
if command -v python3 &> /dev/null; then
    PY_VERSION=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
    log "Python версії $PY_VERSION знайдено."
    # Проста перевірка на версію >= 3.9
    if (( $(echo "$PY_VERSION < 3.9" | bc -l) )); then
        log "УВАГА: Версія Python старіша за 3.9. Рекомендується оновлення."
    fi
else
    log "Встановлення Python 3..."
    apt-get install -y python3 python3-pip python3-venv >> "$LOG_FILE" 2>&1
fi

# Перевірка pip
if ! command -v pip3 &> /dev/null; then
    log "Встановлення pip..."
    apt-get install -y python3-pip >> "$LOG_FILE" 2>&1
fi

# 4. Встановлення Python-бібліотек
log "Перевірка та встановлення Python-залежностей..."

PACKAGES=("django" "torch" "torchvision" "pillow")

for pkg in "${PACKAGES[@]}"; do
    if python3 -c "import $pkg" &> /dev/null; then
        log "Бібліотека $pkg вже встановлена."
    else
        log "Встановлення $pkg..."
        # Використовуємо --ignore-installed, щоб уникнути конфліктів системних пакетів,
        # або краще встановлювати в user space, але ми під sudo, тому ставимо глобально.
        pip3 install "$pkg" --no-cache-dir >> "$LOG_FILE" 2>&1
        if [ $? -eq 0 ]; then
             log "$pkg успішно встановлено."
        else
             log "ПОМИЛКА при встановленні $pkg."
        fi
    fi
done

log "=== Перевірка версій ==="
docker --version | tee -a "$LOG_FILE"
python3 --version | tee -a "$LOG_FILE"
python3 -c "import torch; print(f'Torch version: {torch.__version__}')" | tee -a "$LOG_FILE"

log "=== Налаштування завершено ==="