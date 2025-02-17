#!/bin/bash

set -x


OUTPUT="$(pwd)/output"
RESULT_FILE="${OUTPUT}/result.txt"
LOG_FILE="openposix"
RAVA_REPO="
[openEuler_RAVA_Tools]
name=openEuler:RAVA:Tools (24.03LTS_SP1)
type=rpm-md
baseurl=https://build-repo.tarsier-infra.isrc.ac.cn//openEuler:/RAVA:/Tools/24.03LTS_SP1/
enabled=1
gpgcheck=0
priority=99
"

parse_ltp_output() {
    grep -E "PASS|FAIL|CONF"  "$1" \
        | awk '{print $1" "$2}' \
        | sed 's/PASS/pass/; s/FAIL/fail/; s/CONF/skip/'  >> "${RESULT_FILE}"
}

echo "${RAVA_REPO}" | tee -a /etc/yum.repos.d/openEuler.repo
dnf install -y ltp

echo "Running run-ltp-open-posix"
mkdir -p "${OUTPUT}"
/opt/ltp/runltp -p -f openposix -l "${OUTPUT}/LTP_${LOG_FILE}.log"
parse_ltp_output "${OUTPUT}/LTP_${LOG_FILE}.log"