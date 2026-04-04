#!/usr/bin/env bash
#
# DNS record watcher.
#
# VERSION       :0.2.0
# DATE          :2026-02-17
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# DEPENDS       :apt-get install dnsutils python3
# DEPENDS       :pip install shyaml
# CONFIG        :/etc/dns-watch.yml

set -eo pipefail

shyaml() {
    /usr/local/bin/shyaml "$@" < "$CONFIG"
}

escape_key() {
    local key="$1"
    key="${key//\\/\\\\}"
    key="${key//./\\.}"
    echo "$key"
}

read_config() {
    local ns
    ns="$(shyaml get-value nameserver "" 2>/dev/null || true)"
    echo -e "NSERVER\t${ns}"

    while IFS= read -r -d '' domain; do
        [ "$domain" == "nameserver" ] && continue
        domain_key="$(escape_key "$domain")"

        while IFS= read -r -d '' rtype; do
            rtype_key="${domain_key}.$(escape_key "$rtype")"
            rtype_type="$(shyaml get-type "$rtype_key" 2>/dev/null || true)"

            if [ "$rtype_type" == "sequence" ]; then
                while IFS= read -r -d '' value; do
                    printf '%s\t%s\t-\tudp\tany\t%s\n' "$domain" "$rtype" "$value"
                done < <(shyaml get-values-0 "$rtype_key" 2>/dev/null || true)
                continue
            fi

            if [ "$rtype_type" == "struct" ]; then
                connections_key="${rtype_key}.connections"
                connections_type="$(shyaml get-type "$connections_key" 2>/dev/null || true)"
                if [ "$connections_type" != "sequence" ]; then
                    continue
                fi

                conn_len="$(shyaml get-length "$connections_key" 2>/dev/null || true)"
                conn_len="${conn_len:-0}"
                for ((i=0; i<conn_len; i++)); do
                    conn_key="${connections_key}.${i}"
                    ns_conn="$(shyaml get-value "${conn_key}.nameserver" "" 2>/dev/null || true)"
                    [ -z "$ns_conn" ] && continue

                    while IFS= read -r -d '' field; do
                        [ "$field" == "nameserver" ] && continue
                        field_key="${conn_key}.$(escape_key "$field")"
                        field_type="$(shyaml get-type "$field_key" 2>/dev/null || true)"
                        [ "$field_type" != "sequence" ] && continue

                        proto="udp"
                        family="any"
                        case "$field" in
                            ipv4-udp-rdata) family="4"; proto="udp" ;;
                            ipv4-tcp-rdata) family="4"; proto="tcp" ;;
                            ipv6-udp-rdata) family="6"; proto="udp" ;;
                            ipv6-tcp-rdata) family="6"; proto="tcp" ;;
                            rdata) family="any"; proto="udp" ;;
                        esac

                        while IFS= read -r -d '' value; do
                            printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$domain" "$rtype" "$ns_conn" "$proto" "$family" "$value"
                        done < <(shyaml get-values-0 "$field_key" 2>/dev/null || true)
                    done < <(shyaml keys-0 "$conn_key" 2>/dev/null || true)
                done
            fi
        done < <(shyaml keys-0 "$domain_key" 2>/dev/null || true)
    done < <(shyaml keys-0 2>/dev/null || true)
}

dig_query() {
    local name="$1"
    local rtype="$2"
    local ns="$3"
    local proto="$4"
    local family="$5"
    local -a args=()
    local -a ns_ips_v4=()
    local -a ns_ips_v6=()

    is_ip() {
        local v="$1"
        if [[ "$v" == *:* ]]; then
            return 0
        fi
        [[ "$v" =~ ^[0-9.]+$ ]]
    }

    resolve_ns_ips() {
        local ns_name="$1"
        ns_ips_v4=()
        ns_ips_v6=()

        while IFS= read -r ip; do
            [ -n "$ip" ] && ns_ips_v4+=("$ip")
        done < <(dig +short -4 -t A "$ns_name" 2>/dev/null || true)

        while IFS= read -r ip; do
            [ -n "$ip" ] && ns_ips_v6+=("$ip")
        done < <(dig +short -6 -t AAAA "$ns_name" 2>/dev/null || true)
    }

    run_dig() {
        local ns_arg="$1"
        shift
        dig @"$ns_arg" "$@" +short +time=2 +tries=1 -t "$rtype" "$name" 2>/dev/null || true
    }

    if [ -n "$ns" ] && ! is_ip "$ns"; then
        resolve_ns_ips "$ns"

        if [ "$proto" == "udp" ] && [ "$family" == "any" ]; then
            for ip in "${ns_ips_v4[@]}"; do
                run_dig "$ip" -4
                run_dig "$ip" -4 +tcp
            done
            for ip in "${ns_ips_v6[@]}"; do
                run_dig "$ip" -6
                run_dig "$ip" -6 +tcp
            done
            return 0
        fi
    fi

    case "$family" in
        4) args+=("-4") ;;
        6) args+=("-6") ;;
    esac
    if [ "$proto" == "tcp" ]; then
        args+=("+tcp")
    fi

    if [ -n "$ns" ] && ! is_ip "$ns"; then
        if [ "$family" == "4" ]; then
            for ip in "${ns_ips_v4[@]}"; do
                run_dig "$ip" "${args[@]}"
            done
            [ "${#ns_ips_v4[@]}" -eq 0 ] && run_dig "$ns" "${args[@]}"
            return 0
        fi
        if [ "$family" == "6" ]; then
            for ip in "${ns_ips_v6[@]}"; do
                run_dig "$ip" "${args[@]}"
            done
            [ "${#ns_ips_v6[@]}" -eq 0 ] && run_dig "$ns" "${args[@]}"
            return 0
        fi
    fi

    run_dig "$ns" "${args[@]}"
}

print_block() {
    local text="$1"
    while IFS= read -r line; do
        [ -n "$line" ] || continue
        printf '  %s\n' "$line" 1>&2
    done <<< "$text"
}

CONFIG="/etc/dns-watch.yml"

if [ ! -f "$CONFIG" ]; then
    echo "Config not found: $CONFIG" 1>&2
    exit 2
fi

declare -A EXPECTED=()
declare -A SEEN=()
NAMESERVER="9.9.9.9"

while IFS=$'\t' read -r col1 col2 col3 col4 col5 col6; do
    if [ "$col1" == "NSERVER" ]; then
        NAMESERVER="$col2"
        continue
    fi
    key="${col1}|${col2}|${col3}|${col4}|${col5}"
    EXPECTED["$key"]+="${col6}"$'\n'
    SEEN["$key"]=1
done < <(read_config)

failures=0

if [ -z "$NAMESERVER" ]; then
    echo "Missing nameserver in config" 1>&2
    exit 11
fi

for key in "${!SEEN[@]}"; do
    name="${key%%|*}"
    rest="${key#*|}"
    rtype="${rest%%|*}"
    rest="${rest#*|}"
    ns="${rest%%|*}"
    rest="${rest#*|}"
    proto="${rest%%|*}"
    family="${rest#*|}"

    expected="${EXPECTED[$key]}"
    expected_sorted="$(printf '%s' "$expected" | sed '/^$/d' | sort -u)"
    if [ "$ns" == "-" ] || [ -z "$ns" ]; then
        ns="$NAMESERVER"
    fi
    actual_sorted="$(dig_query "$name" "$rtype" "$ns" "$proto" "$family" | sed '/^$/d' | sort -u)"

    unexpected="$(comm -13 <(printf '%s\n' "$expected_sorted") <(printf '%s\n' "$actual_sorted"))"
    if [ -n "$unexpected" ]; then
        failures=$((failures + 1))
        logger -t dns-watch "CHANGED ${name} ${rtype} ${ns:-default} ${proto}/${family}"
        echo "CHANGED ${name} ${rtype} ${ns:-default} ${proto}/${family}" 1>&2
        echo "  unexpected:" 1>&2
        print_block "$unexpected"
        echo "  expected (all):" 1>&2
        print_block "$expected_sorted"
        echo "  actual:" 1>&2
        print_block "$actual_sorted"
    #else
    #    echo "OK ${name} ${rtype} ${ns:-default} ${proto}/${family}"
    fi
done

if [ "$failures" -gt 0 ]; then
    echo "$failures failures."
fi

exit 0
