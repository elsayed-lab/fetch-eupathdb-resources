#!/usr/bin/env sh
#
# Retrieves the latest versions of several different sequence and annotation
# files for a specified list of organisms available on TriTrypDB and other
# similar resources.
#
# Keith (2015/04/27)
#

# EuPathDB version
eupathdb_version=$(curl http://tritrypdb.org/common/downloads/Current_Release/Build_number)
echo "Retrieving data and annotations for TriTrypDB version " $eupathdb_version

# Root download URLs
tritrypdb_root_url="http://tritrypdb.org/common/downloads/release-$eupathdb_version"
toxodb_root_url="http://www.toxodb.org/common/downloads/release-$eupathdb_version"

# Database filename prefix
tritrypdb_prefix="TriTrypDB"
toxodb_prefix="ToxoDB"

# Root directory for reference data
root_dir=$REF

#
# Download GFF
#
function download_gff() {
    outdir="${root_dir}/${annotation_dir}/"
    gff_filename="${file_prefix}-${eupathdb_version}_${eupathdb_name}.gff"
    gff_url="${root_url}/${eupathdb_name}/gff/data/${gff_filename}"

    echo "Checking for $gff_filename"

    if [ ! -e "${outdir}/${gff_filename}" ]; then
        echo "Downloading ${gff_filename}"
        wget -P ${outdir} ${gff_url}
    fi

    # Create version of GFF with only gene entries and not FASTA sequence
    # Does not appear to be necessary for recent versions of EuPathDB.
    if grep --quiet '^##FASTA' ${outdir}/${gff_filename}; then
        strip_fasta "${outdir}/${gff_filename}"
    fi
}

#
# Download FASTA
#
function download_fasta() {
    outdir="${root_dir}/${genome_dir}/"
    fasta_prefix="${file_prefix}-${eupathdb_version}_${eupathdb_name}"
    url_prefix="${root_url}/${eupathdb_name}/fasta/data"

    genome_fasta_filename="${fasta_prefix}_Genome.fasta"
    genome_fasta_url="${url_prefix}/${genome_fasta_filename}"

    # Genome FASTA
    echo "Checking for $genome_fasta_filename"

    if [ ! -e "${outdir}/${genome_fasta_filename}" ]; then
        echo "Downloading ${genome_fasta_filename}"
        wget -P ${outdir} ${genome_fasta_url}
    fi

    # Check for bowtie2 index
    if [ ! -e "${outdir}/${genome_fasta_filename/fasta/1.bt2}" ]; then
        echo "Building bowtie2 index"
        bowtie2-build ${outdir}/${genome_fasta_filename} ${outdir}/${genome_fasta_filename/.fasta/}
    fi

    # create .fa symlink
    ln -s ${outdir}/${genome_fasta_filename} ${outdir}/${genome_fasta_filename/.fasta/.fa}

    # Annotated Proteins
    protein_fasta_filename="${fasta_prefix}_AnnotatedProteins.fasta"
    protein_fasta_url="${url_prefix}/${protein_fasta_filename}"

    # Genome FASTA
    echo "Checking for $protein_fasta_filename"

    if [ ! -e "${outdir}/${protein_fasta_filename}" ]; then
        echo "Downloading ${protein_fasta_filename}"
        wget -P ${outdir} ${protein_fasta_url}
    fi
}

#
# Download gene text annotations 
#
function download_txt() {
    outdir="${root_dir}/${annotation_dir}/"

    # Gene txt
    gene_txt_filename="${file_prefix}-${eupathdb_version}_${eupathdb_name}${1}.txt"
    gene_txt_url="${root_url}/${eupathdb_name}/txt/${gene_txt_filename}"

    echo "Checking for $gene_txt_filename"
    
    # Gene txt
    if [[ "$1" == "Gene" ]]; then
        if [ ! -e "${outdir}/${gene_txt_filename}.gz" ]; then
            echo "Downloading ${gene_txt_filename}"
            wget -P ${outdir} ${gene_txt_url}
            gzip ${outdir}/${gene_txt_filename}
        fi
    else
        # Codon usage, aliases, etc.
        if [ ! -e "${outdir}/${gene_txt_filename}" ]; then
            echo "Downloading ${gene_txt_filename}"
            wget -P ${outdir} ${gene_txt_url}
        fi
    fi
}

# Removes FASTA sequence section from end of TriTrypDB GFF files
function strip_fasta() {
    # exclude any fasta sections at end of file
    last_line=$(expr $(grep --color='never' -nr "##FASTA" $1 |\
                awk '{print $1}' FS=":") - 1)

    # grab all fields after the FASTA entries
    head -n ${last_line} ${1} >> ${1}.tmp
    mv ${1}.tmp ${1}
}


#
# Main function to download all individual files
#
function fetch_latest() {
    echo "Checking for latest version of $1..."

    eupathdb_name=$1
    annotation_dir="$2/annotation"
    genome_dir="$2/genome"
    root_url=$3
    file_prefix=$4

    #download_fasta
    download_fasta
    download_gff
    download_txt "Gene"
    download_txt "_CodonUsage"
    download_txt "_GeneAliases"
}

# Fetch latest versions of EuPathDB annotations for specified species
fetch_latest 'LmajorFriedlin' 'lmajor_friedlin' $tritrypdb_root_url $tritrypdb_prefix
fetch_latest 'TcruziCLBrener' 'tcruzi_clbrener' $tritrypdb_root_url $tritrypdb_prefix
fetch_latest 'TcruziCLBrenerEsmeraldo-like' 'tcruzi_clbrener_esmeraldo-like' $tritrypdb_root_url $tritrypdb_prefix
fetch_latest 'TcruziCLBrenerNon-Esmeraldo-like' 'tcruzi_clbrener_nonesmeraldo-like' $tritrypdb_root_url $tritrypdb_prefix
fetch_latest 'TbruceiTREU927' 'tbrucei_treu927' $tritrypdb_root_url $tritrypdb_prefix
fetch_latest 'TgondiiME49' 'tgondii_me49' $toxodb_root_url $toxodb_prefix
fetch_latest 'TcruziSylvioX10-1' 'tcruzi_sylvio' $tritrypdb_root_url $tritrypdb_prefix
fetch_latest 'TcruzimarinkelleiB7' 'tcruzi_marinkellei_b7' $tritrypdb_root_url $tritrypdb_prefix


