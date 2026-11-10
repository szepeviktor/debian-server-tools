#!/usr/bin/env bash
#
# Install the original Debian MC binary and its supported user files.
#
# VERSION       :1.0.0
# DATE          :2026-10-25
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# URL           :https://github.com/szepeviktor/debian-server-tools
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+

# Add this to your .bashrc
# test -d /usr/share/mc || export MC_DATADIR=~/.config/mc/

set -euo pipefail

die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
warn() { printf 'WARNING: %s\n' "$*" >&2; }
user_home() { realpath -e -- "${HOME:?HOME is not set}"; }

inside_home() {
    local path
    [[ $1 == /* ]] || die "An absolute destination path is required: $1"
    path=$(realpath -m -- "$1")
    [[ $path == "$mc_user_home/"* && $path != *$'\n'* ]] || die "Path outside HOME: $1"
    [[ ! -L $1 ]] || die "Refusing a symlink destination: $1"
    printf '%s\n' "$path"
}

# Read requirements from the actual .deb; missing packages only produce warnings.
check_dependencies() {
    local field requirements requirement package op wanted status installed
    local -a dependencies
    for field in Pre-Depends Depends Recommends; do
        requirements=$(dpkg-deb -f "$mc_deb" "$field")
        IFS=, read -r -a dependencies <<< "${requirements//$'\n'/ }"
        for requirement in "${dependencies[@]}"; do
            requirement="${requirement#"${requirement%%[![:space:]]*}"}"
            # Handle package names and optional (operator version) requirements.
            read -r package op wanted <<< "${requirement//[()]/}"
            [[ -n $package ]] || continue
            status=missing
            installed=
            if [[ $package == mc-data ]]; then
                status=installed
                installed=$data_version
            else
                read -r status installed < <(dpkg-query -W \
                    -f='${db:Status-Status} ${Version}\n' "$package" 2>/dev/null || true) || true
            fi
            if [[ $status != installed || -z $installed ]]; then
                warn "$field not satisfied: $requirement"
            elif [[ -n $op ]] && ! dpkg --compare-versions "$installed" "$op" "$wanted"; then
                warn "$field not satisfied: $requirement"
            fi
        done
    done
}

copy_config() {
    if [[ -e $2 || -L $2 ]]; then
        warn "Keeping existing configuration: $2"
    else
        cp -- "$1" "$2"
    fi
}

main() {
    [[ $# == 0 ]] || die 'Usage: bash mc-user-debian.sh (run in the directory containing the two .deb files)'
    [[ $EUID != 0 ]] || die 'Run as the normal user, without sudo.'
    for command in dpkg-deb dpkg dpkg-query realpath mktemp cp install sed find; do
        command -v "$command" >/dev/null || die "Required command is missing: $command"
    done
    [[ -z ${MC_PROFILE_ROOT:-} ]] || die 'MC_PROFILE_ROOT is set; unset it before this standard user installation.'
    mc_user_home=$(user_home)
    [[ $mc_user_home != / && -O $mc_user_home ]] || die 'Invalid HOME directory.'

    # Use the original Debian package filenames, including apt's encoded epoch.
    shopt -s nullglob
    local candidate mc_deb data_deb mc_version data_version architecture
    local -a mc_files=(./mc_*.deb) data_files=(./mc-data_*.deb)
    [[ ${#mc_files[@]} == 1 && ${#data_files[@]} == 1 ]] || \
        die 'Exactly one mc_*.deb and one mc-data_*.deb are required in the current directory.'
    mc_deb=${mc_files[0]}
    data_deb=${data_files[0]}
    [[ $(dpkg-deb -f "$mc_deb" Package) == mc ]] || die 'The mc_*.deb file is not an mc package.'
    [[ $(dpkg-deb -f "$data_deb" Package) == mc-data ]] || die 'The mc-data_*.deb file is not an mc-data package.'
    mc_version=$(dpkg-deb -f "$mc_deb" Version)
    data_version=$(dpkg-deb -f "$data_deb" Version)
    [[ $data_version == "$mc_version" ]] || \
        die "Package versions differ: mc=$mc_version, mc-data=$data_version"
    architecture=$(dpkg-deb -f "$mc_deb" Architecture)
    [[ $architecture == "$(dpkg --print-architecture)" ]] || die "Wrong architecture: $architecture"
    [[ $(dpkg-deb -f "$data_deb" Architecture) == all ]] || die 'Unexpected mc-data architecture.'
    check_dependencies

    local bin_dir config_dir data_dir cache_dir state_dir file
    bin_dir=$(inside_home "$mc_user_home/bin")
    config_dir=$(inside_home "${XDG_CONFIG_HOME:-$mc_user_home/.config}/mc")
    data_dir=$(inside_home "${XDG_DATA_HOME:-$mc_user_home/.local/share}/mc")
    cache_dir=$(inside_home "${XDG_CACHE_HOME:-$mc_user_home/.cache}/mc")
    state_dir=$(inside_home "$mc_user_home/.local/state/mc-user-install")
    [[ ! -e $state_dir ]] || die 'This user installation already exists; run mc-user-debian-uninstall.sh first.'
    for file in mc mcedit mcview mcdiff; do
        [[ ! -e $bin_dir/$file && ! -L $bin_dir/$file ]] || die "Already exists: $bin_dir/$file"
    done
    for candidate in "$config_dir" "$data_dir"; do
        if [[ -d $candidate ]] && [[ -n $(find "$candidate" -type l -print -quit) ]]; then
            die "Existing MC directory contains symlinks: $candidate"
        fi
    done

    umask 077
    mc_work=$(mktemp -d "$mc_user_home/.mc-install.XXXXXXXX")
    trap 'rm -rf -- "$mc_work"' EXIT
    trap 'exit 130' INT
    trap 'exit 143' TERM
    mkdir "$mc_work/root"
    dpkg-deb -x "$mc_deb" "$mc_work/root"
    dpkg-deb -x "$data_deb" "$mc_work/root"
    local root="$mc_work/root" ext_source ext_target ext_name

    mkdir -p -- "$state_dir" "$bin_dir" "$config_dir/mcedit" "$data_dir/mcedit"
    printf '%s\n' 'mc-user-shell-v1' "$config_dir" "$data_dir" "$cache_dir" > "$state_dir/paths"
    install -m 755 -- "$root/usr/bin/mc" "$bin_dir/mc"
    for file in mcedit mcview mcdiff; do
        ln -s mc "$bin_dir/$file"
    done

    # MC's built-in user search paths. Package scripts and the ELF stay unchanged.
    cp -a -- "$root/usr/share/mc/skins" "$root/usr/share/mc/syntax" "$data_dir/"
    cp -a -- "$root/usr/lib/mc/extfs.d" "$root/usr/lib/mc/ext.d" "$data_dir/"
    copy_config "$root/usr/share/mc/mc.charsets" "$config_dir/mc.charsets"
    copy_config "$root/etc/mc/edit.indent.rc" "$data_dir/mcedit/edit.indent.rc"
    copy_config "$root/etc/mc/filehighlight.ini" "$config_dir/filehighlight.ini"
    copy_config "$root/etc/mc/mc.menu" "$config_dir/menu"
    copy_config "$root/etc/mc/mcedit.menu" "$config_dir/mcedit/menu"
    copy_config "$root/etc/mc/mc.default.keymap" "$config_dir/mc.keymap"

    # Prefer the INI extension file; older MC packages provide mc.ext instead.
    if [[ -f $root/etc/mc/mc.ext.ini ]]; then
        ext_source=$root/etc/mc/mc.ext.ini
        ext_name=mc.ext.ini
    elif [[ -f $root/usr/share/mc/mc.ext.ini ]]; then
        ext_source=$root/usr/share/mc/mc.ext.ini
        ext_name=mc.ext.ini
    elif [[ -f $root/usr/share/mc/mc.ext ]]; then
        ext_source=$root/usr/share/mc/mc.ext
        ext_name=mc.ext
    elif [[ -f $root/etc/mc/mc.ext ]]; then
        ext_source=$root/etc/mc/mc.ext
        ext_name=mc.ext
    else
        die 'Neither mc.ext.ini nor mc.ext was found in the Debian packages.'
    fi
    # HOME/XDG_DATA_HOME expand in the extension action at runtime.
    # shellcheck disable=SC2016
    sed \
        -e 's@/usr/lib/mc/ext.d/misc.sh view torrent@"${XDG_DATA_HOME:-$HOME/.local/share}/mc/extfs.d/torrent" list "$MC_EXT_FILENAME"@g' \
        -e 's@/usr/lib/mc/ext\.d/\([[:alnum:]_.-]*\)@"${XDG_DATA_HOME:-$HOME/.local/share}/mc/ext.d/\1"@g' \
        "$ext_source" > "$mc_work/$ext_name"
    ext_target=$config_dir/$ext_name
    copy_config "$mc_work/$ext_name" "$ext_target"

    printf '\nInstalled MC %s: %s/mc\n' "$mc_version" "$bin_dir"
    warn 'Without system MC data: no F1 help/translations/hints; codepage selection and SFS are limited.'
    printf 'Uninstall with: bash mc-user-debian-uninstall.sh\n'
    "$bin_dir/mc" --datadir-info
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then main "$@"; fi
