#!/usr/bin/env bash
# https://gist.github.com/natemarks/aebb7e84010d4bc37270d554106cb38b
set -Eeuo pipefail
trap cleanup SIGINT SIGTERM ERR EXIT

INITIAL_WD="$(pwd)"

usage() {
  cat <<EOF
Usage: setup_ansible.sh [-h] [-v]

Use the distribution package manager to install python3 and ansible

Available options:

-h, --help      Print this help and exit
-v, --verbose   Print script debug info
EOF
  exit
}

cleanup() {
  trap - SIGINT SIGTERM ERR EXIT
  cd "${INITIAL_WD}"
}

setup_colors() {
  if [[ -t 2 ]] && [[ -z "${NO_COLOR-}" ]] && [[ "${TERM-}" != "dumb" ]]; then
    NOFORMAT='\033[0m' RED='\033[0;31m' GREEN='\033[0;32m' ORANGE='\033[0;33m' BLUE='\033[0;34m' PURPLE='\033[0;35m' CYAN='\033[0;36m' YELLOW='\033[1;33m'
  else
    # shellcheck disable=SC2034
    NOFORMAT='' RED='' GREEN='' ORANGE='' BLUE='' PURPLE='' CYAN='' YELLOW=''
  fi
}

msg() {
  echo >&2 -e "${1-}"
}

die() {
  local msg=$1
  local code=${2-1} # default exit status 1
  msg "$msg"
  exit "$code"
}

parse_params() {
  # default values of variables set from params

  while :; do
    case "${1-}" in
    -h | --help) usage ;;
    -v | --verbose) set -xv ;;
    --no-color) NO_COLOR=1 ;;
    -?*) die "Unknown option: $1" ;;
    *) break ;;
    esac
    shift
  done

  # check required params and arguments
  # [[ -z "${tf_module-}" ]] && die "Missing required parameter: tf_module"

  return 0
}

parse_params "$@"
setup_colors

# the apt package manage is installed on the system
function is_ubuntu() {
  local STATUS
  grep Ubuntu /etc/os-release 2> /dev/null
  STATUS=$?
  if (( STATUS == 0 )); then
    true
  else
    false
  fi
}

if ! is_ubuntu; then
  die "${RED}This script only supports Ubuntu${NOFORMAT}"
fi
sudo apt install -y python3 python3-pip git
# boto3 and botocore enable the ansible aws features
pip3 install --user ansible boto3 botocore