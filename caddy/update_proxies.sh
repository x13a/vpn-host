#!/usr/bin/env bash
set -euo pipefail

CONFIG_DIR="./config"
KEYCDN_FILE="$CONFIG_DIR/keycdn.caddy"

update_file() {
    local config_file="$1"
    local ips="$2"
    local source_name="$3"

    if [[ ! -f "$config_file" ]]; then
        echo "Error: $config_file not found"
        return 1
    fi

    local tmp_file
    tmp_file="$(mktemp)"

    awk -v ips="$ips" '
    BEGIN {replaced=0}
    {
        if ($1 == "@denied" && $2 == "not" && $3 == "remote_ip") {
            print "@denied not remote_ip " ips
            replaced=1
        } else {
            print $0
        }
    }
    END {
        if (replaced == 0) {
            print "@denied not remote_ip " ips
        }
    }' "$config_file" > "$tmp_file"

    mv "$tmp_file" "$config_file"
    echo "Done: ${source_name}"
}

update_keycdn() {
    local ips_v4 ips_v6 ips ips_json
    ips_json=$(curl -sL https://ip.guide/as44239 | jq .routes)
    ips_v4=$(echo "$ips_json" | jq -r '.v4[]?')
    ips_v6=$(echo "$ips_json" | jq -r '.v6[]?')
    ips=$(echo "$ips_v4 $ips_v6" | tr '\n' ' ' | xargs)
    update_file "$KEYCDN_FILE" "$ips" "keycdn"
}

case "${1:-}" in
    keycdn)
        update_keycdn
        ;;
    all)
        update_keycdn
        ;;
    *)
        echo "Usage: $0 {keycdn|all}"
        exit 1
        ;;
esac
