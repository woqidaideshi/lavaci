#!/bin/bash

set -x

LTP_TMPDIR="/root/ltp-realtime-tmp"
OUTPUT="$(pwd)/output"
RESULT_FILE="${OUTPUT}/result.txt"
LTP_REALTIME_TESTS=""
RAVA_REPO="
[openEuler_RAVA_Tools]
name=openEuler:RAVA:Tools (24.03LTS_SP1)
type=rpm-md
baseurl=https://build-repo.tarsier-infra.isrc.ac.cn/openEuler:/RAVA:/Tools/24.03LTS_SP1/
enabled=1
gpgcheck=0
priority=99
"

while getopts "T:" arg; do
   case "$arg" in
      T)
        LTP_REALTIME_TESTS="${OPTARG}"
        ;;
   esac
done

parse_ltp_realtime_output() {
    pushd "$1"
    for logfile in *.log; do
        if [[ -f "$logfile" ]]; then
            CONFIG_ITEM="${logfile:0:-4}"
            if grep -q "Result: FAIL" "$logfile"; then
                echo $CONFIG_ITEM fail >> "${RESULT_FILE}"
            else
                last_line=$(tail -n 1 "$logfile" | xargs)
                if [[ "$last_line" == *"test appears to have completed." ]]; then
                    echo $CONFIG_ITEM pass >> "${RESULT_FILE}"
                else
                    echo $CONFIG_ITEM fail >> "${RESULT_FILE}"
                fi
            fi
        fi
    done
    popd
}

install_ltp() {
    echo "${RAVA_REPO}" | tee -a /etc/yum.repos.d/openEuler.repo
    dnf install -y ltp
}

run_ltp_realtime() {
    [ -d "${OUTPUT}"/log ] && rm -rf "${OUTPUT}"/log
    mkdir -p "${OUTPUT}"/log
    cd /opt/ltp
    if [ -z "${LTP_REALTIME_TESTS}" ]; then
        for dir in testcases/realtime/func/*/; do
            if [ -d "$dir" ]; then
                TEST="$(basename "$dir")"
                ./testcases/realtime/run.sh -t func/"${TEST}" 2>&1 | tee "${OUTPUT}"/log/"${TEST}".log
            fi
        done
    else
        for TEST in ${LTP_REALTIME_TESTS}; do
            ./testcases/realtime/run.sh -t func/"${TEST}" 2>&1 | tee "${OUTPUT}"/log/"${TEST}".log
        done
    fi
    parse_ltp_realtime_output "${OUTPUT}"/log
}

echo "============== Tests to run ==============="
install_ltp
echo "ltp install completely"
run_ltp_realtime
echo "===========End Tests to run ===============" 


