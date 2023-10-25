#!/bin/bash
# Script to run sispa analysis

usage(){
	echo "Usage: $0 -d [dir] <optional arguments>"
	echo "-d: Experiment directory containing the fastq.gz nanopore reads - Must be included"
	echo "-5: How many bases to trim from the 5 prime end of each read - Default 18"
	echo "-3: How many bases to trim from the 3 prime end of each read - Default 18"
	echo "-k: Run the kraken analysis"
	echo "-s: Sample data in csv format"
	echo "-c: Generate a consensus sequence"
	exit 1
}

arg5=18
arg3=18

while getopts "d:5:3:s:kch" opt; do
	case $opt in
	k)
		kraken=true
		;;
	c)
		consensus=true
		;;
	d)
		startDir="$OPTARG"
		;;
	5)
		arg5="$OPTARG"
		;;
	3)
		arg3="$OPTARG"
		;;
	h)
		usage
		;;
	s)
		sampleData="$OPTARG"
		;;
	\?)
		echo "Invalid option: -$OPTARG" >&2
		exit 1
		;;
	esac
done


if [ -z "$startDir" ]; then
	echo "-d is required"
	usage
fi

echo "Value of -d: $startDir"
echo "Value of -5: $arg5"
echo "Value of -3: $arg3"
workingFolder=sispa_$(basename $startDir)
echo "$workingFolder"

# $startDir has the full path to the directory where the reads are present. Should this assume the nanopore folder structure with fastq_pass folder and dozens of files or would it be best to assume all of the reads have been collected into a single folder? The latter is probably best as it is more versatile but will require adding instructions for how to cat them all together.

mkdir $workingFolder #creates the output dir

#Check if the sispa environment exists, if it does activate it. If it doesn't then create it
myenvs=$(conda env list | grep sispa)
if ! [[ $myenvs =~ "sispa" ]]; then 
	echo "Creating sispa environment"; 
	conda env create -n sispa -c conda-forge -c bioconda -c r -c defaults bracken kraken2 kraken-biom chopper r-base r-curl
else 
	echo "Sispa environment already exists";
fi


if [ -e "/home/cwduffy/kraken_db/microbiome_db/" ]; then
	echo "Exists"
else
	echo "Kraken 2 database is missing. Ask Craig to install it"
fi

#Code here for how to download and set up the kraken database - this takes a long time and the files are really big so it is better to have a single copy available to all. You must ensure that the path to it is accessible to all users and reflects your system
#conda run -n sispa kraken2-build --download-taxonomy --threads 150 --db microbiome_db
#conda run -n sispa kraken2-build --download-library bacteria --threads 150 --db microbiome_db
#conda run -n sispa kraken2-build --download-library viral --threads 150 --db microbiome_db
#conda run -n sispa kraken2-build --download-library fungi --threads 150 --db microbiome_db
#conda run -n sispa kraken2-build --build --threads 150 --db microbiome_db

#for i in $startDir/*gz; do
#	echo $i
#	j=$(basename $i)
#	k=${j/.fastq.gz/}
#	time gunzip -c $i | conda run -n sispa --no-capture-output chopper --headcrop 18 --tailcrop 18 -l 100 --threads 56 | pigz > $workingFolder/trimmed_$j
#done

if $kraken; then
	for j in $workingFolder/trimmed*gz; do
		k=$(basename $j)
		#conda run -n sispa kraken2 --db /home/cwduffy/kraken_db/microbiome_db/ --use-names --threads 56 --report $workingFolder/$k.report.txt --output $workingFolder/$k.kraken $j
	done
	conda run -n sispa kraken-biom $workingFolder/*txt -o $workingFolder/OUTPUT_FP
	# Run the R script on each of the files
	echo $sampleData $workingFolder
	conda run -n sispa Rscript sispa.r $workingFolder $sampleData
fi

#if($consensus){
	#
	#}


#rm -f $workingFolder/trimmed_$j

#Need to add check for chimeric reads containing the sispa barcodes.

# Load the data into R and run the analysis there