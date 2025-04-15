#!/bin/bash

set -x

source ../../lib/sh-test-lib.sh

USERNAME=trinity
OUTPUT="$(pwd)/output"
RESULT_FILE="${OUTPUT}/result.txt"
TEST_NUMBER=28200
RAVA_REPO="
[openEuler_RAVA_Tools]
name=openEuler:RAVA:Tools (24.03LTS_SP1)
type=rpm-md
baseurl=https://build-repo.tarsier-infra.isrc.ac.cn//home:/yafen:/branches:/openEuler:/RAVA:/Tools/24.03LTS_SP1/
enabled=1
gpgcheck=0
priority=99
"

while getopts "T:" arg; do
   case "$arg" in
      T)
        TEST_NUMBER="${OPTARG}"
        ;;
   esac
done

add_user(){
    if ! id "${USERNAME}" >/dev/null 2>&1; then
        echo "creating ${USERNAME} user..."
        useradd "${USERNAME}"
    else
        echo "${USERNAME}" exist
    fi
}

install_trinity() {
    echo "${RAVA_REPO}" | tee -a /etc/yum.repos.d/openEuler.repo
    dnf install -y trinity
}

run_trinity() {
    mkdir -p "${OUTPUT}"
    if [ -d "${TMP_OUTPUT}" ]; then
        rm -rf "${TMP_OUTPUT}"
    fi
    export TMP_OUTPUT=/home/"${USERNAME}"/trinity
    export TEST_NUMBER=${TEST_NUMBER}
    su "${USERNAME}" <<'EOF'
cd
mkdir -p "${TMP_OUTPUT}"
echo start: trinity -qq -l off -C$(nproc) -N"${TEST_NUMBER}" -l "${TMP_OUTPUT}"
trinity -qq -l off -C$(nproc) -N"${TEST_NUMBER}" -l "${TMP_OUTPUT}"
EOF
    mv "${TMP_OUTPUT}" "${OUTPUT}"
    unset TEST_NUMBER
    unset TMP_OUTPUT
    measurement=$(grep -m 1 "Ran" "${OUTPUT}/trinity/trinity.log" | awk '{print $6 / $3 * 100}')
    add_metric "trinity" "pass" "${measurement}" "%"
}

echo "============== Tests to run ==============="
install_trinity
echo "trinity install completely"
add_user
echo "add user ${USERNAME} completely"
run_trinity
echo "===========End Tests to run ===============" 
