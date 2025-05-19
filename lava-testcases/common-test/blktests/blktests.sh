#!/bin/bash

set -x

LTP_TMPDIR="/root/blktests-tmp"
OUTPUT="$(pwd)/output"
RESULT_FILE="${OUTPUT}/result.txt"
TEST_ITEMS="block"
DISK_FILTER="6G"
RAVA_REPO="
[openEuler_RAVA_Tools]
name=openEuler:RAVA:Tools (24.03LTS_SP1)
type=rpm-md
baseurl=https://build-repo.tarsier-infra.isrc.ac.cn/home:/yafen:/branches:/openEuler:/RAVA:/Tools/24.03LTS_SP1/
enabled=1
gpgcheck=0
priority=99
"

while getopts "T:F:" arg; do
   case "$arg" in
      T)
        TEST_ITEMS="${OPTARG}"
        ;;
      F)
        DISK_FILTER="${OPTARG}"
        ;;
      ?)
        echo "Usage: $0 -F <DISK_FILTER> -T <TEST_ITEMS>"
        exit 1
        ;;
   esac
done


parse_blktests_output() {
    while IFS= read -r line; do
        if [[ "$line" =~ \[(.*)\] ]]; then
            status="${BASH_REMATCH[1]}"
            case "$status" in
                passed)
                    new_status="pass"
                    ;;
                failed)
                    new_status="fail"
                    ;;
                "not run")
                    new_status="skip"
                    ;;
                *)
                    new_status="unknown"
                    ;;
            esac
            test_item=${line%%(*}
            test_item=$(echo $test_item | sed 's/ //g')
            if [[ "$test_item" == *"=>"* ]]; then
                test_item="${test_item/=>/(}"
                test_item="${test_item})"
            fi
            echo "${test_item} ${new_status}" >> "${RESULT_FILE}"
        fi
    done < "$1"
}


install_blktests() {
    echo "${RAVA_REPO}" | tee -a /etc/yum.repos.d/openEuler.repo
    dnf install -y blktests
}

run_blktests() {
    cd /usr/lib/blktests
    mkdir -p "${OUTPUT}"

    DEVICES=$(lsblk | grep "${DISK_FILTER}" | awk '{print $1}')
    if [ -z "${DEVICES}" ]; then
        echo Disk of size "${DISK_FILTER}" not detected.
        exit 1
    fi
    TEST_DEVS_STR="TEST_DEVS=("
    for dev in $DEVICES; do
        TEST_DEVS_STR="${TEST_DEVS_STR}/dev/$dev "
    done

    TEST_DEVS_STR="${TEST_DEVS_STR%?})"
    echo $TEST_DEVS_STR > config
    echo "QUICK_RUN=1" >> config
    echo "TIMEOUT=90" >> config
    cat config

    echo start: ./check "${TEST_ITEMS}" | tee "${OUTPUT}"/blktests.log
    ./check "${TEST_ITEMS}" | tee "${OUTPUT}"/blktests.log
    parse_blktests_output "${OUTPUT}"/blktests.log
    cat "${OUTPUT}"/blktests.log
    cat "${RESULT_FILE}"
}

echo "============== Tests to run ==============="
install_blktests
echo "blktests install completely"
run_blktests
echo "===========End Tests to run ==============="
