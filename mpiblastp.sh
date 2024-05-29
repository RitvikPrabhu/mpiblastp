#!/bin/bash

# Define the paths for the dataset fragments and the query file
NUM_WORKERS=$1
NCBI_BLAST_PATH=${2:-"ncbi-blast-2.13.0+/bin"}
DATASET_DIR=${3:-"tmp"}
QUERY_FILE=${4:-"data/g50.fasta"}
SHARED_RESULT_DIR=${5:-"output"}
MASTER_RESULT_FILE=${6:-"${SHARED_RESULT_DIR}/unsorted_result.fasta"}

# Get the list of hostnames
HOSTS=($(scontrol show hostnames $SLURM_NODELIST))
# Distribute the fragments and query files to worker nodes using rsync
#for i in $(seq 1 $NUM_WORKERS); do
  #WORKER_HOST=${HOSTS[$i]}
  #FORMATTED_I=$(printf "%02d" $i)
  #rsync -avz $QUERY_FILE ${WORKER_HOST}:/tmp/query_file.fasta
  #rsync -avz ${DATASET_DIR}/segment_${FORMATTED_I}.fasta* ${WORKER_HOST}:/tmp/
#done

mpirun --map-by ppr:1:node:pe=48 ./mpiblastp_workerProcess.sh $QUERY_FILE $NCBI_BLAST_PATH


> $MASTER_RESULT_FILE
for i in $(seq 1 $NUM_WORKERS); do
  WORKER_HOST=${HOSTS[$i]}
  FORMATTED_I=$(printf "%02d" $i)
  #rsync -avz ${WORKER_HOST}:/tmp/result_${FORMATTED_I}.fasta $SHARED_RESULT_DIR/result_${FORMATTED_I}.fasta
  cat $SHARED_RESULT_DIR/result_${FORMATTED_I}.fasta >> $MASTER_RESULT_FILE
done

echo "Master process: All results have been combined into $MASTER_RESULT_FILE"


#./mpiblastp_masterProcess.sh $NUM_WORKERS $SHARED_RESULT_DIR $MASTER_RESULT_FILE
