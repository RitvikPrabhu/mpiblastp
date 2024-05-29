#!/bin/bash

DBFILE=$1
QUERYFILE=$2
NNODES=$3
ELAPSE=${4:-30:00}
TIME_LOG_FILE=${5:-"blastp_time.log"}
BLASTP_OUTPUT=${6:-"blastp_output.fasta"}

USAGE="$0 \${DBFILE} \${QUERYFILE} \${NNODES} [ELAPSE] [TIME_LOG_FILE] [BLASTP_OUTPUT]"
if [ -z ${NNODES} ]; then
  echo "NNODES not set!"
  echo ${USAGE}
  exit 1
fi
if [ ! -f data/${DBFILE} ]; then
    echo "Could not find data/${DBFILE}"
    echo ${USAGE}
    exit 1;
fi
if [ ! -f data/${QUERYFILE} ]; then
    echo "Could not find data/${QUERYFILE}"
    echo ${USAGE}
    exit 1;
fi

HOST_OUTPUT_DIR="./output"
HOST_DATA_DIR="./data"
HOST_TMP_DIR="./tmp"
NCBI_BLAST_PATH="ncbi-blast-2.13.0+/bin"
SLURM_ARGS=(
 -N $NNODES
 -p short
 --ntasks-per-node=48
 --cpus-per-task=1
 -A pn_cis240131
 --time ${ELAPSE}
 )

TMPFILE=$(mktemp)
cat > $TMPFILE << EOF
#!/bin/bash
module load openmpi/gcc13.1.0/4.1.5

mkdir -p tmp output

echo "Splitting and Formatting Dataset..."
./mpiformatdb.sh ${HOST_DATA_DIR}/${DBFILE} $NNODES ${HOST_TMP_DIR} ${NCBI_BLAST_PATH} ${HOST_DATA_DIR} ${DBFILE}

./mpiblastp.sh $NNODES

echo "BLAST job completed."
EOF

sbatch ${SLURM_ARGS[@]} $TMPFILE

