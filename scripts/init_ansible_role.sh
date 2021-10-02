#!/usr/bin/env bash
# https://gist.github.com/natemarks/aebb7e84010d4bc37270d554106cb38b
set -Eeuo pipefail
trap cleanup SIGINT SIGTERM ERR EXIT

INITIAL_WD="$(pwd)"

usage() {
  cat <<EOF
Usage: init_ansible_role.sh [-h] [-v] -r role_name

Initialize a new ansible role
.
If docker is installed, use the ansible toolset image. If not, use venv to get molecule

Available options:

-h, --help      Print this help and exit
-v, --verbose   Print script debug info
EOF
  exit
}

cleanup() {
  trap - SIGINT SIGTERM ERR EXIT
  cd "${INITIAL_WD}"
  rm -rf .venv
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
  role_name=''

  while :; do
    case "${1-}" in
    -h | --help) usage ;;
    -v | --verbose) set -xv ;;
    --no-color) NO_COLOR=1 ;;
    -r | --role_name) # example named parameter
      role_name="${2-}"
      shift
      ;;
    -?*) die "Unknown option: $1" ;;
    *) break ;;
    esac
    shift
  done

  # check required params and arguments
  [[ -z "${role_name-}" ]] && die "Missing required parameter: role_name"

  return 0
}

parse_params "$@"
setup_colors

# the apt package manage is installed on the system
function docker_is_installed() {
  local STATUS
  which docker > /dev/null 2>&1
  STATUS=$?
  if (( STATUS == 0 )); then
    true
  else
    false
  fi
}

if docker_is_installed; then
  docker run --rm -i \
  -v "$(pwd)":/tmp/role \
  quay.io/ansible/toolset:latest /bin/bash -c  \
  "molecule init role ${role_name} && cp -R ${role_name} /tmp/role"
else
  rm -rf .venv
  python3 -m venv .venv
  # shellcheck disable=SC1091
  . .venv/bin/activate
  pip install --upgrade pip setuptools
  pip install  ansible molecule
  molecule init role "${role_name}"
fi