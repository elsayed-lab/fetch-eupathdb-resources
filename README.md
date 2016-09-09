fetch_latest.sh
===============

A simple shell script to automate the process of downloading EuPathDB resources
of interest for a given set of organisms.

To use, place the script in the base directory where you plan to download
resources to.

Edit `fetch_latest.sh` to include the databases and organisms you wish to
retrieve, and run to download all corresponding resources.

Currently the script automates the downloading of:

1. Genome FASTA
2. Annotated Proteins FASTA
3. Annotated CDSs FASTA
4. Genome GFF
5. Genome annotation TXT
6. Codon usage TXT
7. Gene aliases TXT

Large files such as the genome annoation TXT are gzipped, and bowtie2 indices
are built for each genome FASTA file.
