#!/usr/bin/env bash
set -Eeuo pipefail

: "${SAMBA:="Y"}"

[[ "$SAMBA" != [Yy1]* ]] && return 0
[[ "$NETWORK" != [Yy1]* ]] && return 0

hostname="host.lan"
interface="dockerbridge"

if [[ "$DHCP" == [Yy1]* ]]; then
  hostname="$IP"
  interface="$VM_NET_DEV"
fi

share="/shared"

if [ ! -d "$share" ] && [ -d "$STORAGE/shared" ]; then
  share="$STORAGE/shared"
fi

mkdir -p "$share"
[ -z "$(ls -A "$share")" ] && chmod 777 "$share"

{      echo "--------------------------------------------------------"
        echo " $APP for Docker v$(</run/version)..."
        echo " For support visit $SUPPORT"
        echo "--------------------------------------------------------"
        echo ""
        echo "Using this folder you can share files with the host machine."
        echo ""
        echo "To change its location, include the following bind mount in your compose file:"
        echo ""
        echo "  volumes:"
        echo "    - \"/home/user/example:/shared\""
        echo ""
        echo "Or in your run command:"
        echo ""
        echo "  -v \"/home/user/example:/shared\""
        echo ""
        echo "Replace the example path /home/user/example with the desired shared folder."
        echo ""
} | unix2dos > "$share/readme.txt"

! smbd && smbd --debug-stdout

isXP="N"

if [ -f "$STORAGE/windows.old" ]; then
  MT=$(<"$STORAGE/windows.old")
  [[ "${MT,,}" == "pc-q35-2"* ]] && isXP="Y"
fi

if [[ "$isXP" == [Yy1]* ]]; then
  [[ "$DHCP" == [Yy1]* ]] && return 0
  # Enable NetBIOS on Windows XP
  ! nmbd && nmbd --debug-stdout
else
  # Enable Web Service Discovery
  wsdd -i "$interface" -p -n "$hostname" &
  echo "$!" > /var/run/wsdd.pid
fi

return 0
