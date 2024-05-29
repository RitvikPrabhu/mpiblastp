#!/bin/bash

# Usage: ./split_query.sh query.fasta num_segments /path/to/output_dir /path/to/ncbi_blast /container/data/dir dbfile
# Example: ./split_query.sh my_sequences.fasta 5 /path/to/output_dir /usr/local/ncbi/blast/bin /data container_db

if [ $# -ne 6 ]; then
    echo "Usage: $0 query.fasta num_segments /path/to/output_dir /path/to/ncbi_blast /container/data/dir dbfile"
    exit 1
fi

input_file="$1"  
num_segments="$2" 
output_dir="$3"
NCBI_BLAST_PATH="$4"
CONTAINER_DATA_DIR="$5"
DBFILE="$6"

total_sequences=$(grep -c '^>' "$input_file")

sequences_per_segment=$(( (total_sequences + num_segments - 1) / num_segments))

awk -v num_seqs="$sequences_per_segment" -v num_segments="$num_segments" -v output_dir="$output_dir" -v blast_path="$NCBI_BLAST_PATH" -v container_dir="$CONTAINER_DATA_DIR" -v dbfile="$DBFILE" '
  BEGIN {
    n_seq = 0;
    part = 0;
    outfile = sprintf("%s/segment_%02d.fasta", output_dir, part+1);
  }
  function makeblastdb(file) {
    close(file);
    command = sprintf("%s/makeblastdb -in \"%s\" -dbtype prot", blast_path, file);
    system(command);
  }  /^>/ {
    if (n_seq++ % num_seqs == 0 && part != num_segments) {
      makeblastdb(outfile);
      part++;
      outfile=sprintf("'$output_dir'/segment_%02d.fasta", part);
    }
    print >> outfile;
    next;
  }
  {print >> outfile}
  END {
    makeblastdb(outfile);
  }
' "$input_file"

echo "$num_segments segments made"
echo "Segments saved in the '$output_dir' directory."
echo "BLAST databases created for each segment."
