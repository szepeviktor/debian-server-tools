#!/bin/bash
#
# Explain Intel CPU flags.
#
# VERSION       :0.2.1
# LOCATION      :/usr/local/bin/cpuflags.sh

CPUFEATURES_URL="https://git.kernel.org/cgit/linux/kernel/git/stable/linux-stable.git/plain/arch/x86/include/asm/cpufeatures.h"

set -e

CPUFEATURES="$(mktemp)"

# Display CPU details
grep -E "model name|cpu MHz|bogomips" /proc/cpuinfo

# Download cpufeatures.h
wget -nv -O "$CPUFEATURES" "$CPUFEATURES_URL"

# shellcheck disable=SC2013
for FLAG in $(grep -m 1 '^flags' /proc/cpuinfo | cut -d ":" -f 2-); do
    echo -n "$FLAG"
    grep -E -C 1 '^#define X86_(FEATURE|BUG)_' "$CPUFEATURES" \
        | grep -E -i -m 1 "/\\* \"${FLAG}\"|^#define X86_(FEATURE|BUG)_${FLAG}" \
        | grep -o './\*.\+\*/' || echo " N/A"
done

rm -f "$CPUFEATURES"
