#!/usr/bin/env bash
set -Eeuo pipefail
trap cleanup SIGINT SIGTERM ERR EXIT


usage() {
  cat <<EOF
Usage: deploy_artifact_to_s3.sh [-h] [-v] -a artifact -d destination

Given an artifact as the s3 path to a tarball file (ex. s3://repo_bucket/component/component_version.tar.gz) and a
destination as the s3 path to a folder (ex. s3://destination_bucket/path/to/content), this script will download the
artifact, expand it, and copy the contents to the destination folder.

Available options:

-h, --help      Print this help and exit
-v, --verbose   Print script debug info
-a, --artifact     ex. s3://repo_bucket/component/component_version.tar.gz
-d, --destination  ex. s3://destination_bucket/path/to/content
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
  artifact=''
  destination=''

  while :; do
    case "${1-}" in
    -h | --help) usage ;;
    -v | --verbose) set -xv ;;
    --no-color) NO_COLOR=1 ;;
    -a | --artifact)
      artifact="${2-}"
      shift
      ;;
    -d | --destination)
      destination="${2-}"
      shift
      ;;
    -?*) die "Unknown option: $1" ;;
    *) break ;;
    esac
    shift
  done

  # check required params and arguments
  [[ -z "${artifact-}" ]] && die "Missing required parameter: artifact"
  [[ -z "${destination-}" ]] && die "Missing required parameter: destination"

  return 0
}

parse_params "$@"
setup_colors

## strip .tar.gz suffix and replace with txt
tarball_to_txt() {
  local string="$1"
  local tarball_extension=".tar.gz"

  # Check if the string ends with the specified tarball_extension
  if [[ $string == *"$tarball_extension" ]]; then
    # Remove the tarball_extension from the string
    echo "${string%$tarball_extension}".txt
  fi
}

# given an artifact s3 path, return the tarball file name
tarball_file_from_artifact() {
  local input_string="$1"
  IFS='/' read -ra fields <<< "$input_string"
  local last_field="${fields[-1]}"
  echo "$last_field"
}

msg "${RED}Read parameters:${NOFORMAT}"
msg "- artifact: ${artifact}"
msg "- destination: ${destination}"

checksum_uri=$(tarball_to_txt "${artifact}")
[[ -z "$checksum_uri" ]] && die "unable to get checksum_uri from ${artifact}"
msg "- checksum_uri: ${checksum_uri}"

working_dir="$(pwd)/artifact_temp"
if [[ -d "${working_dir}" ]]; then rm -rf "${working_dir}"; fi
mkdir -p "${working_dir}"

aws s3 cp "${artifact}" "${working_dir}"
msg "${GREEN}${artifact} downloaded to ${working_dir}${NOFORMAT}"
aws s3 cp "${checksum_uri}" "${working_dir}"
msg "${GREEN}${checksum_uri} downloaded to ${working_dir}${NOFORMAT}"

# get the tarball file name to extract
tarball_file=$(tarball_file_from_artifact "${artifact}")
[[ -z "$tarball_file" ]] && die "unable to get tarball_file from ${artifact}"

# get the checksum file name
checksum_file=$(tarball_to_txt "${tarball_file}")
[[ -z "$checksum_file" ]] && die "unable to get checksum_file from ${tarball_file}"

mkdir -p "${working_dir}/extracted"
tar -xzvf "${working_dir}/${tarball_file}" -C "${working_dir}/extracted"

# verify integrity
cd "${working_dir}/extracted"
if ! sha256sum -c "${working_dir}/${checksum_file}"; then
  die "extracted contents failed integrity check"
fi

aws s3 cp "${working_dir}/extracted" "${destination}" --recursive
