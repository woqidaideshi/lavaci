#!/bin/bash

set -x

ARRAY_SIZE="10000000"
EXECUTION_COUNT="30"


usage() {
    echo "Usage: ${0} [-s DSTREAM_ARRAY_SIZE]
                      [-c DNTIMES]
                      [-n OMP_NUM_THREADS]
" 1>&2
    exit 0
}

while getopts "s:c:n:" arg; do
  case "$arg" in
    s)
      ARRAY_SIZE="${OPTARG}"
      ;;
    c)
      EXECUTION_COUNT="${OPTARG}"
      ;;
    ?)
      usage
      echo "unrecognized argument ${OPTARG}"
      ;;
  esac
done

yum install -y gcc
wget https://www.cs.virginia.edu/stream/FTP/Code/stream.c
gcc -O3 -fopenmp -DSTREAM_ARRAY_SIZE=${ARRAY_SIZE} -DNTIMES=${EXECUTION_COUNT} stream.c -o stream
./stream
