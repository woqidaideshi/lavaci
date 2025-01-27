#!/bin/bash

set -x

source ../../lib/sh-test-lib.sh

TEST_TMPDIR="/root/unixbench"
OUTPUT="$(pwd)/output"
RESULT_FILE="${OUTPUT}/result.txt"

log_parser() {
    prefix="$1"
    logfile="$2"

    # Test Result.
    grep -E "[0-9.]+ [a-zA-Z]+ +\([0-9.]+ s," "${logfile}" \
        | awk -v prefix="${prefix}" '{printf(prefix)};{for (i=1;i<=(NF-6);i++) printf("-%s",$i)};{printf(" pass %s %s\n"),$(NF-5),$(NF-4)}' \
        | tee -a "${RESULT_FILE}"

    # Index Values.
    grep -E "[0-9]+\.[0-9] +[0-9]+\.[0-9] +[0-9]+\.[0-9]" "${logfile}" \
        | awk -v prefix="${prefix}" '{printf(prefix)};{for (i=1;i<=(NF-3);i++) printf("-%s",$i)};{printf(" pass %s index\n"),$NF}' \
        | tee -a "${RESULT_FILE}"

    ms=$(grep "System Benchmarks Index Score" "${logfile}" | awk '{print $NF}')
    add_metric "${prefix}-System-Benchmarks-Index-Score" "pass" "${ms}" "index"
}

yum install -y git gcc make
mkdir -p "${TEST_TMPDIR}"
cd "${TEST_TMPDIR}"
git clone https://github.com/kdlucas/byte-unixbench.git
cd byte-unixbench/UnixBench
make

# Run a single copy.
mkdir -p "${OUTPUT}"
./Run -c 1 | tee "${OUTPUT}/unixbench-single.txt"
log_parser "single" "${OUTPUT}/unixbench-single.txt"

# Run the number of CPUs copies.
if [ "$(nproc)" -gt 1 ]; then
    ./Run -c "$(nproc)" | tee "${OUTPUT}/unixbench-multiple.txt"
    log_parser "multiple" "${OUTPUT}/unixbench-multiple.txt"
fi