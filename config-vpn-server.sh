#!/bin/bash

# Прерывать выполнение при любой ошибке
set -e

# Цвета для красивого вывода
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}=== 1. Обновление системы ===${NC}"
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get upgrade -y

echo -e "${CYAN}=== 2. Установка базовых утилит ===${NC}"
apt-get install -y curl wget git iptables ufw coreutils jq tar unzip

echo -e "${CYAN}=== 3. Оптимизация сети ===${NC}"
# Включение BBR для ускорения VPN-трафика
if ! grep -q "net.core.default_qdisc=fq" /etc/sysctl.conf; then
    echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
fi

# Включение форвардинга пакетов
if ! grep -q "net.ipv4.ip_forward=1" /etc/sysctl.conf; then
    echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
fi

# Применяем настройки sysctl
sysctl -p

echo -e "${CYAN}=== 4. Настройка Firewall (UFW) ===${NC}"
# Сброс настроек по умолчанию (запретить всё входящее, разрешить исходящее)
ufw default deny incoming
ufw default allow outgoing

# Разрешаем SSH (Порт 22)
ufw allow 22/tcp

# Включаем Firewall без интерактивного запроса [y/n]
ufw --force enable

echo -e "${CYAN}=== 5. Установка 3x-ui ===${NC}"
# Запускаем официальный скрипт в режиме авто-установки (без вопросов пользователю)
# Он сам сгенерирует случайный логин, пароль и секретный веб-путь
bash <(bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)) y

# Получаем внешний IP сервера для вывода в итоге
SERVER_IP=$(curl -s ifconfig.me || curl -s icanhazip.com)

echo -e "${GREEN}=== ИТОГ ===${NC}"
echo -e "${GREEN}Сервер успешно настроен для вашего VPN-сервиса!${NC}"
echo -e "--------------------------------------------------"
echo -e "1. Система обновлена и оптимизирована (BBR включен)."
echo -e "2. Firewall активен. Открыты порты: 22 (SSH) и 2053 (3x-ui)."
echo -e "3. Панель 3x-ui успешно установлена."
echo -e ""
echo -e "Чтобы узнать сгенерированные данные для входа в панель,"
echo -e "выполните на сервере команду: ${CYAN}x-ui settings${NC}"
echo -e "Или найдите их в логах выше."
echo -e "--------------------------------------------------"
