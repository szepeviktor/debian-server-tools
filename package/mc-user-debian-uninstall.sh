#!/usr/bin/env bash
#
# Remove this user installation and all of its MC user settings/data/cache.
#
# VERSION       :1.0.0
# DATE          :2026-10-25
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# URL           :https://github.com/szepeviktor/debian-server-tools
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+

set -euo pipefail

die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
user_home() { realpath -e -- "${HOME:?HOME is not set}"; }

main() {
    [[ $# == 0 ]] || die 'Usage: bash mc-user-debian-uninstall.sh'
    [[ $EUID != 0 ]] || die 'Run as the normal user, without sudo.'
    local mc_user_home state_dir bin_dir path resolved executable name
    local -a paths
    mc_user_home=$(user_home)
    [[ $mc_user_home != / && -O $mc_user_home ]] || die 'Invalid HOME directory.'
    state_dir="$mc_user_home/.local/state/mc-user-install"
    bin_dir="$mc_user_home/bin"
    [[ -e $state_dir || -L $state_dir ]] || { printf 'MC user installation is already absent.\n'; return; }
    [[ ! -L $state_dir && ! -L $state_dir/paths ]] || die 'Invalid installation record.'
    mapfile -t paths < "$state_dir/paths"
    [[ ${#paths[@]} == 4 && ${paths[0]} == mc-user-shell-v1 ]] || die 'Invalid installation record.'
    # Validate everything before deleting anything. Never follow links outside HOME.
    for path in "$state_dir" "$bin_dir" "${paths[@]:1}" "$mc_user_home/.mc"; do
        resolved=$(realpath -m -- "$path")
        [[ $path == "$mc_user_home/"* && $resolved == "$mc_user_home/"* ]] || die "Path outside HOME: $path"
        [[ ! -L $path ]] || die "Refusing a symlink directory: $path"
    done
    for path in "${paths[@]:1}"; do
        [[ ${path##*/} == mc ]] || die "Unexpected MC data directory: $path"
    done
    for executable in /proc/[0-9]*/exe; do
        [[ $(readlink -- "$executable" 2>/dev/null || true) != "$bin_dir/mc" ]] || die 'MC is running; close it first.'
    done
    if [[ -e $bin_dir/mc || -L $bin_dir/mc ]]; then
        [[ -f $bin_dir/mc && ! -L $bin_dir/mc ]] || die 'The installed mc binary was replaced.'
    fi
    for name in mcedit mcview mcdiff; do
        path="$bin_dir/$name"
        if [[ -e $path || -L $path ]]; then
            [[ -L $path && $(readlink -- "$path") == mc ]] || die "Command was replaced: $path"
        fi
    done
    rm -f -- "$bin_dir/mc" "$bin_dir/mcedit" "$bin_dir/mcview" "$bin_dir/mcdiff"
    # Also purges pre-existing MC settings kept by mc-user-debian.sh, and legacy ~/.mc.
    # rm does not follow symlinks contained inside these trees.
    rm -rf -- "${paths[@]:1}" "$mc_user_home/.mc" "$state_dir"
    printf 'Removed MC, settings, history, editor data, skins, helpers and caches.\n'
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then main "$@"; fi
