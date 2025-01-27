#!/bin/sh

add_metric() {
    if [ "$#" -lt 3 ]; then
        warn_msg "The number of parameters less then 3"
        error_msg "Usage: add_metric test_case result measurement [units]"
    fi
    
    local test_case="$1"
    local result="$2"
    local measurement="$3"
    local units="$4"

    echo "${test_case} ${result} ${measurement} ${units}" | tee -a "${RESULT_FILE}"
}