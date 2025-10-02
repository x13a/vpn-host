#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="./config/cloudflare.caddy"
TMP_FILE="$(mktemp)"

ips_v4=$(curl -s https://www.cloudflare.com/ips-v4)
ips_v6=$(curl -s https://www.cloudflare.com/ips-v6)

all_ips=$(echo "$ips_v4 $ips_v6" | tr '\n' ' ' | xargs)
awk -v ips="$all_ips" '
BEGIN {replaced=0}
{
    if ($1 == "trusted_proxies" && $2 == "static") {
        print "trusted_proxies static " ips
        replaced=1
    } else {
        print $0
    }
}
END {
    if (replaced == 0) {
        print "trusted_proxies static " ips
    }
}
' "$CONFIG_FILE" > "$TMP_FILE"

mv "$TMP_FILE" "$CONFIG_FILE"
echo "Done"
