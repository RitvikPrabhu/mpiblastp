#!/bin/bash

NCBI_BLAST_PATH=$1
NTHREADS=$2
#queries=$(cat tmp/query_$OMPI_COMM_WORLD_RANK.fasta)

# Wait until the state file is created by the master process
while [ ! -f "tmp/state_$OMPI_COMM_WORLD_RANK" ]; do
  sleep 1
done
current_state=$(cat tmp/state_$OMPI_COMM_WORLD_RANK)
while [ "$current_state" != "SEARCH_COMPLETE" ]; do
  if [ "$current_state" == "SEARCH_FRAGMENT" ] && [ ! -f "tmp/results_$OMPI_COMM_WORLD_RANK.fasta" ]; then
    fragment=$(cat tmp/fragment_$OMPI_COMM_WORLD_RANK.out)
    if [ ! -f "$fragment" ]; then
      cp $fragment tmp/
    fi
    ${NCBI_BLAST_PATH}/blastp -query tmp/query_$OMPI_COMM_WORLD_RANK.fasta -db tmp/$(basename $fragment) -evalue 0.000001 -max_target_seqs 10 -outfmt 6 -num_threads $NTHREADS -out tmp/results_${OMPI_COMM_WORLD_RANK}_temp.fasta
    sed -i "1i$fragment" tmp/results_${OMPI_COMM_WORLD_RANK}_temp.fasta
    mv tmp/results_${OMPI_COMM_WORLD_RANK}_temp.fasta tmp/results_$OMPI_COMM_WORLD_RANK.fasta
    echo "idle" > tmp/idle_$OMPI_COMM_WORLD_RANK
  fi
  current_state=$(cat tmp/state_$OMPI_COMM_WORLD_RANK)
done
echo "Process with rank $OMPI_COMM_WORLD_RANK completed"

