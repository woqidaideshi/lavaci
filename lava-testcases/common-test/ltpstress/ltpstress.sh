#!/bin/bash

set -x

LTP_TMPDIR="/root/ltpstress-tmp"
OUTPUT="$(pwd)/output"
RESULT_FILE="${OUTPUT}/result.txt"
TST_CMDFILES="-p -n -m 512 -t 1"
RAVA_REPO="
[openEuler_RAVA_Tools]
name=openEuler:RAVA:Tools (24.03LTS_SP1)
type=rpm-md
baseurl=https://build-repo.tarsier-infra.isrc.ac.cn//openEuler:/RAVA:/Tools/24.03LTS_SP1/
enabled=1
gpgcheck=0
priority=99
"

while getopts "T:" arg; do
   case "$arg" in
      T)
        TST_CMDFILES="${OPTARG}"
        ;;
   esac
done


parse_ltpstress_output() {
    grep -E "PASS|FAIL|CONF"  "$1" \
        | awk '{print $1" "$2}' \
        | sed 's/PASS/pass/; s/FAIL/fail/; s/CONF/skip/'  >> "${RESULT_FILE}"
}


install_ltp() {
    echo "${RAVA_REPO}" | tee -a /etc/yum.repos.d/openEuler.repo
    dnf install -y ltp
}

run_ltpstress() {
    # cd /opt/ltp
    mkdir -p "${OUTPUT}"
    echo start: /opt/ltp/testscripts/ltpstress.sh ${TST_CMDFILES} -l
    /opt/ltp/testscripts/ltpstress.sh "${TST_CMDFILES}" -l "${OUTPUT}/ltpstress.log"
    parse_ltpstress_output "${OUTPUT}/ltpstress.log"
}

echo "============== Tests to run ==============="
install_ltp
echo "ltp install completely"
run_ltpstress
echo "===========End Tests to run ===============" 


