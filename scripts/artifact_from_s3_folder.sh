#!/usr/bin/env bash
set -Eeuo pipefail
trap cleanup SIGINT SIGTERM ERR EXIT


usage() {
  cat <<EOF
Usage: artifact_from_s3_folder.sh [-h] [-v] [-f] -p param_value arg1 [arg2...]

Downloads the contents of an s3 folder and creates a a "${release_id}.tar.gz" file and "${release_id}.txt" sha256sum
file in the destination directory

I recommend making sure that the source folder always contains a version.txt file that can identify the source code

Available options:

-h, --help      Print this help and exit
-v, --verbose   Print script debug info
-s, --source          ex. s3://my_bucket/path/to/folder
-d, --destination     ex. /abs/path/to/folder or rel/path/to/folder
-r, --release_id      ex. component_v0.1.2
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
  source=''
  destination=''
  release_id='component_v0.1.2'

  while :; do
    case "${1-}" in
    -h | --help) usage ;;
    -v | --verbose) set -xv ;;
    --no-color) NO_COLOR=1 ;;
    -s | --source) # source folder
      source="${2-}"
      shift
      ;;
    -d | --destination) # destination directory
      destination="${2-}"
      shift
      ;;
    -r | --release_id) # release id
      release_id="${2-}"
      shift
      ;;
    -?*) die "Unknown option: $1" ;;
    *) break ;;
    esac
    shift
  done

  # check required params and arguments
  [[ -z "${source-}" ]] && die "Missing required parameter: source"
  [[ -z "${destination-}" ]] && die "Missing required parameter: destination"
  [[ -z "${release_id-}" ]] && die "Missing required parameter: release_id"

  return 0
}

parse_params "$@"
setup_colors
# set up working dir
working_dir="${destination}/${release_id}_temp"
if [[ -d "${working_dir}" ]]; then rm -rf "${working_dir}"; fi
mkdir -p "${working_dir}"

# download s3 contents to a local folder
aws s3 sync "${source}" "${working_dir}"

# create a checksum file for the contents
cd "${working_dir}"
find . -type f -exec sha256sum {} + | sort >"${destination}/${release_id}.txt"
tar -czvf "${destination}/${release_id}".tar.gz -C "${working_dir}" .
