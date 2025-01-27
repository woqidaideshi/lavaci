#!/bin/bash

set -x

LTP_TMPDIR="/root/ltp-tmp"
OUTPUT="$(pwd)/output"
RESULT_FILE="${OUTPUT}/result.txt"
TST_CMDFILES=""
LOG_FILE="alltest"
LTP_VERSION="20240930"
TEST_PROGRAM=ltp
TEST_DIR="$(pwd)/${TEST_PROGRAM}"


while getopts "T:" arg; do
   case "$arg" in
      T)
        TST_CMDFILES="${OPTARG}"
        LOG_FILE=$(echo "${OPTARG}"| sed 's/,/_/g')
        ;;
   esac
done


parse_ltp_output() {
    grep -E "PASS|FAIL|CONF"  "$1" \
        | awk '{print $1" "$2}' \
        | sed 's/PASS/pass/; s/FAIL/fail/; s/CONF/skip/'  >> "${RESULT_FILE}"
}


install_ltp() {
    dnf install -y git make automake gcc clang pkgconf autoconf bison flex m4 kernel-headers glibc-headers clang findutils libtirpc libtirpc-devel pkg-config
    mkdir -p "${LTP_TMPDIR}"
    cd "${LTP_TMPDIR}"
    wget https://github.com/linux-test-project/ltp/releases/download/"${LTP_VERSION}"/ltp-full-"${LTP_VERSION}".tar.xz
    tar -xvf ltp-full-"${LTP_VERSION}".tar.xz
    cd ltp-full-"${LTP_VERSION}"
    make autotools
    ./configure
    make -j$(nproc)
    make install
}

run_ltp() {
    cd /opt/ltp
    mkdir -p "${OUTPUT}"
    if [ -z "${TST_CMDFILES}" ]; then
        ./runltp -p -l ${OUTPUT}/LTP_${LOG_FILE}.log
    else
        ./runltp -p -f "${TST_CMDFILES}" -l ${OUTPUT}/LTP_${LOG_FILE}.log
    fi
    parse_ltp_output "${OUTPUT}/LTP_${LOG_FILE}.log"
}

echo "============== Tests to run ==============="
install_ltp
echo "ltp install completely"
run_ltp
echo "===========End Tests to run ===============" 


