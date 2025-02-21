#!/bin/sh
set -euf

die() {
  if [ $# -gt 0 ]; then
    >&2 printf "$@"
  fi
  exit 1
}

usage() {
  printf 'Usage: %s <tty-device>\n' "${0##*/}"
}

if [ $# -ne 1 ]; then
  usage >&2
  exit 2
fi

device="$1";shift
baud=115200

[ -c "${device}" ] || die "%s is not a character device\n" "${device}"
stty -F "${device}" "${baud}" pass8 raw

color() {
  local num=$1
  if [ ${num} -eq 0 ]; then
    printf '0'
  else
    printf '%d' "$((num % 7 + 31 + ((num / 7) % 2) * 60))"
  fi
  #printf '%s: %d\n' "${num}" "$((num % 7 + 31 + ((num / 7) % 2) * 60))" >&2
}


colorize_streams() {
  local dev="$1";shift
  local num=0
  printf 'Sources:\n'
  for arg in "$@"; do
    printf '  \x1b[%dm%s\x1b[0m\n' "$(color "${num}")" "${arg}"
    num=$((num + 1))
  done
  num=0
  argc="$#"
  while [ "${num}" -lt "${argc}" ]; do
    local tag="${1%%:*}";shift
    set -- "$@" -e "$(printf 's/\\xff\\x%02x/\\x1b[%dm/g' "${tag}" "$(color "${num}")")"
    num=$((num + 1))
  done
  sed --binary --unbuffered \
    "$@" \
    "${dev}"
#  if tty; then
#    stty raw
#    cat > "${dev}"
#  fi
}

colorize_streams "${device}" \
    '0xe1:CCPLEX' \
    '0xe5:RCE' \
    '0xe6:FSI' \
    '0xe7:PSCFW' \
    '0xe8:DCE' \
    '0xe2:BPMP' \
    '0xe3:SCE' \
    '0xe0:SPE' \
    '0xe4:TZ' \
    '0xe9:HPSE' \
    '0xea:SB' \
    '0xeb:ADSP0' \
    '0xec:ADSP1' \
    '0xed:UTC0' \
    '0xee:UTC1' \
    '0xef:UTC2' \
    '0xf0:UTC3'
