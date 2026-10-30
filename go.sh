#!/bin/bash
# Запуск стенда на Маке, когда ноутбук до него не достаёт (сеть с изоляцией клиентов), SAF-4198.
# Публичный файл: секретов здесь нет. На Маке:  curl -fsSL sic-stand-a.github.io/go.sh | bash
export PATH="/opt/homebrew/bin:$PATH"
T=SAF-4198
echo "== сеть"
IF=$(route -n get default 2>/dev/null | awk '/interface:/{print $2}')
IP=$(ipconfig getifaddr "$IF" 2>/dev/null)
GW=$(route -n get default 2>/dev/null | awk '/gateway:/{print $2}')
WIFI=$(networksetup -listallhardwareports 2>/dev/null | awk '/Wi-Fi/{getline; print $2}')
SSID=$(networksetup -getairportnetwork "$WIFI" 2>/dev/null | sed 's/^Current Wi-Fi Network: //')
echo "интерфейс: ${IF:-нет}  адрес: ${IP:-нет}  шлюз: ${GW:-нет}  Wi-Fi: ${SSID:-?}"
NET=""
for u in https://api.linear.app https://api.anthropic.com https://github.com; do
  c=$(curl -s -o /dev/null -m 10 -w '%{http_code}' "$u"); echo "$u -> $c"; NET="$NET ${u#https://}=$c"
done
echo "== фабрика"
bash ~/sic_stand/watcher/factory-run.sh
sleep 8
ST=$(bash ~/sic_stand/watcher/factory-state.sh 2>/dev/null | head -1)
echo "состояние: $ST"
echo "== отчёт в Linear ($T)"
mkdir -p /Users/Shared/sic_stand
F="/Users/Shared/sic_stand/go-$(date +%s).md"
{
  echo "🤖 sic_stand · Мак запущен локально ($(date '+%d.%m.%Y %H:%M'))"
  echo
  echo "- сеть: интерфейс \`${IF:-нет}\`, адрес \`${IP:-нет}\`, шлюз \`${GW:-нет}\`, Wi-Fi \`${SSID:-?}\`"
  echo "- интернет:$NET"
  echo "- фабрика: \`$ST\`"
} > "$F"
if ~/sic_stand/tools/stand-linear comment "$T" --file "$F" >/dev/null 2>&1; then
  echo "отчёт отправлен"
else
  echo "отчёт в Linear не ушёл — пришли фото этого окна"
fi
echo "Готово. Окно можно закрыть."
