#!/bin/bash

DELAYED_QUEUE_KEY_TPL='*_database_queues:default:delayed'
JOB_NUMBER="1"

DELAYED_QUEUE_KEY="$(echo "KEYS \"${DELAYED_QUEUE_KEY_TPL}\"" | redis-cli -n 0 | head -n 1)"
test -n "${DELAYED_QUEUE_KEY}" || exit 1
REDIS_LIST_CMD="ZRANGE ${DELAYED_QUEUE_KEY} 0 -1"

CURRENT_JOB="$(redis-cli -n 0 <<<"${REDIS_LIST_CMD}" | head -n "${JOB_NUMBER}" | tail -n 1)"
#JOB_COUNT="$(redis-cli -n 0 <<<"${REDIS_LIST_CMD}" | wc -l)"

# Display job paramteres
jq 'del(."data"."command")' <<<"${CURRENT_JOB}"

# Diplay unserialized PHP object
jq -r '."data"."command"' <<<"${CURRENT_JOB}" \
    | php -r 'var_export(unserialize(stream_get_contents(STDIN)));echo "\n";' \
#    | bat --paging never --language php
