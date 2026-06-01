#!/bin/bash
#
# Add the repositories that you install software from.
#
# VERSION       :0.4.0
# DATE          :2026-05-31
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# URL           :https://github.com/szepeviktor/debian-server-tools
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# LOCATION      :/usr/local/sbin/apt-add-repo.sh

# Usage
#
#     apt-add-repo.sh nodejs percona

set -euo pipefail

D="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
APT_SOURCES_DIR="/etc/apt/sources.list.d"
APT_PREFERENCES_DIR="/etc/apt/preferences.d"

find_source_file() {
    local locations=(
        "${D}/apt-sources/${REPO}.sources"
        "${D}/package/apt-sources/${REPO}.sources"
        "./package/apt-sources/${REPO}.sources"
        "./${REPO}.sources"
        "/usr/local/src/debian-server-tools/package/apt-sources/${REPO}.sources"
        "/root/src/debian-server-tools-master/package/apt-sources/${REPO}.sources"
    )
    local location

    for location in "${locations[@]}"; do
        if [[ -r "$location" ]]; then
            printf '%s\n' "$location"
            return 0
        fi
    done

    return 1
}

read_field() {
    local field="$1"
    local file="$2"

    awk -F ': ' -v field="$field" '
        tolower($1) == tolower(field) {
            print substr($0, index($0, ":") + 2)
            exit
        }
    ' "$file" || true
}

normalize_fingerprint() {
    printf '%s' "$1" | tr -d '[:space:]' | tr '[:lower:]' '[:upper:]'
}

key_fingerprint() {
    local key_file="$1"

    gpg --show-keys --with-colons "$key_file" \
        | awk -F ':' '$1 == "fpr" { print $10; exit }'
}

stage_preference_file() {
    local repo="$1"
    local staged_source="$2"
    local preference_file="${APT_PREFERENCES_DIR}/${repo}.pref"
    local pref_content=""

    pref_content="$(read_field "X-Pref-Content" "$staged_source")"
    if [[ -z "$pref_content" ]]; then
        return 0
    fi

    mkdir -p "$APT_PREFERENCES_DIR"
    printf '%b' "$pref_content" >"$preference_file"
}

stage_keyring() {
    local staged_source="$1"
    local signed_by=""
    local key_url=""
    local key_format=""
    local expected_fingerprint=""
    local temp_download=""
    local temp_keyring=""
    local current_fingerprint=""

    signed_by="$(read_field "Signed-By" "$staged_source")"
    if [[ -z "$signed_by" ]]; then
        return 0
    fi

    key_url="$(read_field "X-Key-URL" "$staged_source")"
    if [[ -z "$key_url" ]]; then
        return 0
    fi

    key_format="$(read_field "X-Key-Format" "$staged_source")"
    if [[ -z "$key_format" ]]; then
        echo "[CRITICAL] Missing X-Key-Format in ${staged_source}" 1>&2
        return 1
    fi

    expected_fingerprint="$(normalize_fingerprint "$(read_field "X-Key-Fingerprint" "$staged_source")")"
    mkdir -p "$(dirname "$signed_by")"
    temp_download="$(mktemp)"
    temp_keyring="$(mktemp)"

    if ! wget -q -O "$temp_download" "$key_url"; then
        rm -f "$temp_download" "$temp_keyring"
        return 1
    fi

    case "$key_format" in
        armored)
            if ! gpg --batch --yes --dearmor --output "$temp_keyring" "$temp_download"; then
                rm -f "$temp_download" "$temp_keyring"
                return 1
            fi
            ;;
        binary)
            if ! install -m 0644 "$temp_download" "$temp_keyring"; then
                rm -f "$temp_download" "$temp_keyring"
                return 1
            fi
            ;;
        *)
            echo "[CRITICAL] Unsupported X-Key-Format '${key_format}' in ${staged_source}" 1>&2
            rm -f "$temp_download" "$temp_keyring"
            return 1
            ;;
    esac

    if [[ -n "$expected_fingerprint" ]]; then
        current_fingerprint="$(normalize_fingerprint "$(key_fingerprint "$temp_keyring")")"
        if [[ "$current_fingerprint" != "$expected_fingerprint" ]]; then
            echo "[CRITICAL] Fingerprint mismatch: (${current_fingerprint} <> ${expected_fingerprint})" 1>&2
            rm -f "$temp_download" "$temp_keyring"
            return 1
        fi
    fi

    if ! install -m 0644 "$temp_keyring" "$signed_by"; then
        rm -f "$temp_download" "$temp_keyring"
        return 1
    fi
    rm -f "$temp_download" "$temp_keyring"
}

cleanup_repo_artifacts() {
    local repo="$1"
    local staged_source="$2"
    local signed_by=""

    signed_by="$(read_field "Signed-By" "$staged_source" 2>/dev/null)"
    rm -f "${staged_source}" "${APT_PREFERENCES_DIR}/${repo}.pref"

    if [[ -n "$signed_by" ]]; then
        rm -f "${signed_by}"
    fi
}

stage_repo() {
    local repo="$1"
    local source_file="$2"
    local staged_source=""

    staged_source="${APT_SOURCES_DIR}/$(basename "$source_file")"
    mkdir -p "$APT_SOURCES_DIR"
    install -m 0644 "$source_file" "$staged_source"
    stage_keyring "$staged_source" || return 1
    stage_preference_file "$repo" "$staged_source" || return 1
}

if [[ "$#" -eq 0 ]]; then
    echo "Usage: ${0##*/} <repo> [<repo> ...]" 1>&2
    exit 64
fi

for REPO in "$@"; do
    SOURCE_FILE="$(find_source_file)" || {
        echo "[CRITICAL] Repository source not found: ${REPO}.sources" 1>&2
        exit 2
    }

    if ! stage_repo "$REPO" "$SOURCE_FILE"; then
        cleanup_repo_artifacts "$REPO" "${APT_SOURCES_DIR}/$(basename "$SOURCE_FILE")"
        exit 1
    fi
done

apt-get clean
apt-get update
