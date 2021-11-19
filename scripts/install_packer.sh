#!/usr/bin/env bash

set -Eeuo pipefail
trap cleanup SIGINT SIGTERM ERR EXIT

usage() {
  cat <<EOF
Usage: install_packer.sh [-h] [-v] -r release_version -d directory

Downloads and extracts packer to the [directory/version].  Echoes the PATH update export command
Running the script with no options will install the default version to build/packer/[DEFAULT VERSION]/
Available options:

-h, --help        Print this help and exit
-v, --verbose     Print script debug info
-r, --release_version  packer version, default: 1.7.6
-d  --directory   directory to download and extract packer
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
  release_version='1.7.6'
  directory='build/terraform'

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

# download 1.7.6 build/packer
#  https://releases.hashicorp.com/packer/1.7.6/packer_1.7.6_darwin_amd64.zip to
# build/packer/1.7.6 and unzip it
# NOTE
function download() {
  OS=$(uname)
  readonly OS
  if [ "${OS}" == "Darwin" ]; then
    TARBALL="packer_${1}_darwin_amd64.zip"
  else
    TARBALL="packer_${1}_linux_amd64.zip"
  fi

  if [ -d "${2}/${1}" ]; then
    return 0
  fi
  mkdir -p "${2}/${1}"

  curl -L "https://releases.hashicorp.com/packer/${1}/${TARBALL}" \
  -o "${2}/${1}/${TARBALL}" \
  --silent
  unzip "${2}/${1}/${TARBALL}" -d "${2}/${1}"
}
download "${release_version}" "${directory}"
# echo the path to the packer executable.
# the calling function can use this output to run the executable or modify the path
echo "${directory}/${release_version}"