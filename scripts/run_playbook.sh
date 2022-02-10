#!/usr/bin/env bash
# https://gist.github.com/natemarks/aebb7e84010d4bc37270d554106cb38b
set -Eeuo pipefail
trap cleanup SIGINT SIGTERM ERR EXIT

MAKEMINE="/etc/makemine/makemine.yaml"
declare -r MAKEMINE

# shellcheck disable=SC2034
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

usage() {
  cat <<EOF
Usage: run_playbook.sh [-h] [-v] -p playbook

Script description here.

Available options:

-h, --help      Print this help and exit
-v, --verbose   Print script debug info
-p, --playbook  Playbook name:  ./${playbook}/${playbook}.yml
EOF
  exit
}

cleanup() {
  trap - SIGINT SIGTERM ERR EXIT
  # script cleanup here
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
  playbook=''

  while :; do
    case "${1-}" in
    -h | --help) usage ;;
    -v | --verbose) set -xv ;;
    --no-color) NO_COLOR=1 ;;
    -p | --playbook) # example named parameter
      playbook="${2-}"
      shift
      ;;
    -?*) die "Unknown option: $1" ;;
    *) break ;;
    esac
    shift
  done

  # check required params and arguments
  [[ -z "${playbook-}" ]] && die "Missing required parameter: playbook"

  return 0
}

parse_params "$@"
setup_colors

sudo apt install -y curl
bash -c 'curl "https://raw.githubusercontent.com/natemarks/pipeline-scripts/v0.0.25/scripts/setup_ansible.sh" | sudo bash -s'

# run the requirements file if it exists.install will fail on an empty requirements.yml
if [ -f "${playbook}/${playbook}.yml" ]; then
    ansible-galaxy install -r "${playbook}/requirements.yml" --force
fi
# some example playbooks use roledir to run the role from the current path

ROLE_DIR="$(pwd)"
export ROLE_DIR

if [ -f "${MAKEMINE}" ]; then
    ansible-playbook --extra-vars "@${MAKEMINE}" "${playbook}/${playbook}.yml" -K
else
    ansible-playbook "${playbook}/${playbook}.yml" -K
fi
