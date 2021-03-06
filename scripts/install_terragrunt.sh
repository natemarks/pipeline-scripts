#!/usr/bin/env bash

set -Eeuo pipefail
trap cleanup SIGINT SIGTERM ERR EXIT

usage() {
  cat <<EOF
Usage: utility.sh [-h] [-v] -r release_version -d directory

Downloads and extracts terragrunt to the [directory/version].  Echoes the PATH update export command
Running the script with no options will install the default version to build/terragrunt/[DEFAULT VERSION]/

Available options:

-h, --help        Print this help and exit
-v, --verbose     Print script debug info
-r, --release_version  terragrunt version, default: 0.31.3
-d  --directory   directory to download and extract terragrunt
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
  release_version='0.31.3'
  directory='build/terragrunt'

  while :; do
    case "${1-}" in
    -h | --help) usage ;;
    -v | --verbose) set -xv ;;
    --no-color) NO_COLOR=1 ;;
    -r | --release_version) # example named parameter
      release_version="${2-}"
      shift
      ;;
    -d | --directory) # example named parameter
      directory="${2-}"
      shift
      ;;
    -?*) die "Unknown option: $1" ;;
    *) break ;;
    esac
    shift
  done

  return 0
}

parse_params "$@"
setup_colors

# script logic here

msg "${RED}Read parameters:${NOFORMAT}"
msg "- release_version: ${release_version}"
msg "- directory: ${directory}"

# download 0.13.7 build/terraform
# https://github.com/gruntwork-io/terragrunt/releases/download/v0.31.3/terragrunt_darwin_amd64
# build/terraform/0.13.7 and unzip it
# NOTE
function download() {

  OS=$(uname)
  readonly OS
  if [ "${OS}" == "Darwin" ]; then
    TARBALL="terragrunt_darwin_amd64"
  else
    TARBALL="terragrunt_linux_amd64"
  fi

  if [ -d "${2}/${1}" ]; then
    return 0
  fi
  mkdir -p "${2}/${1}"

  curl -L "https://github.com/gruntwork-io/terragrunt/releases/download/v${1}/${TARBALL}" \
  -o "${2}/${1}/terragrunt" \
  --silent
  chmod 755 "${2}/${1}/terragrunt"
}
download "${release_version}" "${directory}"
echo "export PATH=${directory}/${release_version}:$PATH"