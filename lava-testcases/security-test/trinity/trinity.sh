#!/bin/bash

set -x

USERNAME=trinity
OUTPUT="$(pwd)/output"
RESULT_FILE="${OUTPUT}/result.txt"
TEST_NUMBER=28200
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
        TEST_DURATION="${OPTARG}"
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
    su - "${USERNAME}" <<'EOF'
mkdir -p trinity
echo start: trinity -qq -l off -C$(nproc) -N"${TEST_NUMBER}" -l ./trinity
trinity -qq -l off -C$(nproc) -N"${TEST_NUMBER}" -l ./trinity
EOF
    mv /home/"${USERNAME}"/trinity "${OUTPUT}"
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
