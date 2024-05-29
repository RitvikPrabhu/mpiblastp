#!/bin/bash

QUERY_FILE=$1
NCBI_BLAST_PATH=$2
RANK=$(printf "%02d" $(($OMPI_COMM_WORLD_RANK + 1)))
DB_FILE="tmp/segment_${RANK}.fasta"
RESULT_FILE="output/result_${RANK}.fasta"


${NCBI_BLAST_PATH}/blastp -query $QUERY_FILE -db $DB_FILE -evalue 0.000001 -max_target_seqs 10 -outfmt 6 -num_threads 48 -out $RESULT_FILE

echo "Worker process on $(hostname): Results saved to $RESULT_FILE"
