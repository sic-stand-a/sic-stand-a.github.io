#!/bin/bash
# Tailscale на Мак стенда, чтобы ноутбук видел его из любой сети (SAF-4198).
# Публичный файл: секретов здесь нет. На Маке:  curl -fsSL sic-stand-a.github.io/ts.sh | bash
set -u
export PATH="/opt/homebrew/bin:$PATH"
T=SAF-4198
TS=/Applications/Tailscale.app/Contents/MacOS/Tailscale
report(){
  mkdir -p /Users/Shared/sic_stand
  F="/Users/Shared/sic_stand/ts-$(date +%s).md"
  printf '%s\n' "$1" > "$F"
  ~/sic_stand/tools/stand-linear comment "$T" --file "$F" >/dev/null 2>&1 && echo "(отчёт ушёл в Linear $T)"
}
if [ ! -x "$TS" ]; then
  echo "== ставлю Tailscale. Сейчас попросит пароль Мака (символы при вводе не видны) — введи и Enter."
  curl -fsSL -o /tmp/Tailscale.pkg https://pkgs.tailscale.com/stable/Tailscale-latest-macos.pkg || { echo "не скачалось"; exit 1; }
  sudo installer -pkg /tmp/Tailscale.pkg -target / || { echo "установка не прошла"; exit 1; }
fi
open -a Tailscale
echo
echo "== Мак может показать окна Tailscale: про VPN и системное расширение."
echo "   Везде нажимай Allow / Разрешить. Если просит зайти в Системные настройки →"
echo "   Конфиденциальность и безопасность — там внизу кнопка «Разрешить» для Tailscale."
echo "   Входить в учётную запись в окне Tailscale на Маке НЕ нужно — ссылку подтвердишь на ноутбуке."
echo
for i in $(seq 1 120); do
  out=$("$TS" status 2>&1 | head -1)
  case "$out" in *"failed to connect"*|*"not running"*|"") sleep 5;; *) break;; esac
done
"$TS" up --hostname=sics-mac-mini --timeout=0 > /tmp/ts-up.log 2>&1 &
URL=""
for i in $(seq 1 24); do
  URL=$(grep -o 'https://login.tailscale.com/[^ ]*' /tmp/ts-up.log 2>/dev/null | head -1)
  [ -n "$URL" ] && break
  "$TS" ip -4 >/dev/null 2>&1 && break
  sleep 5
done
if [ -n "$URL" ]; then
  echo "== ссылка для входа Мака (подтверди на ноутбуке): $URL"
  report "🤖 sic_stand · вход Мака в Tailscale — открой на ноутбуке и подтверди: $URL"
fi
IP=""
for i in $(seq 1 120); do
  IP=$("$TS" ip -4 2>/dev/null | head -1)
  [ -n "$IP" ] && break
  sleep 5
done
if [ -n "$IP" ]; then
  echo "== готово: Мак в Tailscale, адрес $IP"
  report "🤖 sic_stand · Мак в Tailscale: адрес \`$IP\`, имя \`sics-mac-mini\` ($(date '+%d.%m %H:%M'))"
else
  echo "== вход не подтверждён за 10 минут — запусти эту же строку ещё раз"
  tail -5 /tmp/ts-up.log
fi
