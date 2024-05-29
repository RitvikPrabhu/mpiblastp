#!/bin/bash

DBFILE=$1
QUERYFILE=$2
BLASTP_OUTPUT=$3
NCBI_BLAST_PATH=$4
NTASKS=$5



if [ -z "$OMPI_COMM_WORLD_RANK" ]; then
  echo "OMPI_COMM_WORLD_RANK is not set"
  exit 1
fi

if [ "$OMPI_COMM_WORLD_RANK" -eq 0 ]; then
  ./mpiblastp_masterProcess.sh "${DBFILE}" "${QUERYFILE}" "${BLASTP_OUTPUT}" "${NCBI_BLAST_PATH}"
else
  ./mpiblastp_workerProcess.sh "${NCBI_BLAST_PATH}" "${NTASKS}"
fi

