#!/bin/bash

DBFILE=$1
QUERYFILE=$2
BLASTP_OUTPUT=$3
NCBI_BLAST_PATH=${4:-"/opt/ncbi-blast-2.13.0+/bin"}
HOST_OUTPUT_DIR="./output"
HOST_DATA_DIR="./data"
HOST_TMP_DIR="./tmp"

# Initialize state
results=()
fragments=($(ls ${HOST_TMP_DIR}/segment_*.fasta))
unsearched=(${fragments[@]})
unassigned=(${fragments[@]})
workers=($(seq 1 $(($OMPI_COMM_WORLD_SIZE - 1))))
declare -A worker_fragments
declare -A distributed
# Broadcast queries to all workers
queries=$(cat ${HOST_DATA_DIR}/${QUERYFILE})
for worker in "${workers[@]}"; do
  echo "$queries" > tmp/query_$worker.fasta
  echo "idle" > tmp/idle_$worker
done

# Master process logic
while [ ${#unsearched[@]} -gt 0 ]; do

  for worker in "${workers[@]}"; do
    if [ ! -f "tmp/idle_$worker" ]; then
      continue
    fi

    rm "tmp/idle_$worker"

    if [ ${#unassigned[@]} -eq 0 ]; then
      echo "SEARCH_COMPLETE" > tmp/state_$worker
    else
      fragment=${unassigned[0]}
      unassigned=("${unassigned[@]:1}") 
      distributed[$fragment]+="$worker "
      echo "SEARCH_FRAGMENT" > tmp/state_$worker
      echo "$fragment" > tmp/fragment_$worker.out
    fi
  done

  echo -n "" > ${HOST_OUTPUT_DIR}/${BLASTP_OUTPUT}
  for worker in "${workers[@]}"; do
    if [ -f "tmp/results_$worker.fasta" ]; then
      #result=$(cat tmp/results_$worker)
      #results+=("$result")
      tail -n +2 "tmp/results_$worker.fasta" >> ${HOST_OUTPUT_DIR}/${BLASTP_OUTPUT}
      #fragment=$(echo "$result" | cut -d ' ' -f 1)
      fragment=$(head -n 1 "tmp/results_$worker.fasta")
      unsearched=(${unsearched[@]/$fragment})
      rm tmp/results_$worker.fasta
    fi
  done
done

# Set barrier synchronization
for worker in "${workers[@]}"; do
  echo "SEARCH_COMPLETE" > tmp/state_$worker
done

# Wait for all worker processes to reach the barrier
while true; do
  barrier_reached=1
  for worker in "${workers[@]}"; do
    current_state=$(cat tmp/state_$worker)
    if [ "$current_state" != "SEARCH_COMPLETE" ]; then
      barrier_reached=0
      break
    fi
  done
  if [ $barrier_reached -eq 1 ]; then
    break
  else
    sleep 1
  fi
done

# Print results
echo "Results written to ${HOST_OUTPUT_DIR}/${BLASTP_OUTPUT}"

