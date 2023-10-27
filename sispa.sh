#!/bin/bash
# Script to run sispa analysis

usage(){
	echo "Usage: $0 -d [dir] <optional arguments>"
	echo "-d: [directory] Experiment directory containing the fastq.gz nanopore reads - Must be included"
	echo "-5: [value] How many bases to trim from the 5 prime end of each read - Default 18"
	echo "-3: [value] How many bases to trim from the 3 prime end of each read - Default 18"
	echo "-k: Run the kraken analysis"
	#echo "-s: Sample data in csv format"
	echo "-c: [ref.feasta] Generate a consensus sequence by mapping to supplied reference file"
	exit 1
}

arg5=18
arg3=18
kraken=false

while getopts "d:5:3:s:c:kh" opt; do
	case $opt in
	k)
		kraken=true
		;;
	c)
		consensus="$OPTARG"
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
	r)
		ref="$OPTARG"
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
	conda env create -n sispa -c conda-forge -c bioconda -c r -c defaults bracken kraken2 kraken-biom chopper r-base r-curl minimap2 samtools krona bcftools
	conda run -n sispa ktUpdateTaxonomy.sh
else 
	echo "Sispa environment already exists";
fi


if [ -e "/home/cwduffy/kraken_db/virus/" ]; then
	echo "Kraken2 nt database exists"
else
	echo "Kraken 2 database is missing. Ask Craig to install it"
	exit 1
fi

#Code here for how to download and set up the kraken database - this takes a long time and the files are really big so it is better to have a single copy available to all. You must ensure that the path to it is accessible to all users and reflects your system
#conda run -n sispa kraken2-build --download-taxonomy --threads 150 --db microbiome_db
#conda run -n sispa kraken2-build --download-library bacteria --threads 150 --db microbiome_db
#conda run -n sispa kraken2-build --download-library viral --threads 150 --db microbiome_db
#conda run -n sispa kraken2-build --download-library fungi --threads 150 --db microbiome_db
#conda run -n sispa kraken2-build --build --threads 150 --db microbiome_db

#for i in $startDir/*gz; do
#	echo $i
#	echo "Trimming reads"
#	j=$(basename $i)
#	k=${j/.fastq.gz/}
#	time gunzip -c $i | conda run -n sispa --no-capture-output chopper --headcrop 18 --tailcrop 18 -l 100 --threads 56 | pigz -p 56 > $workingFolder/trimmed_$j
#done


#Kraken / bracken analysis
if $kraken; then
	echo "Running Kraken, bracken and krona for all samples"
	for j in $workingFolder/trimmed*gz; do
		k=$(basename $j)
		conda run -n sispa kraken2 --db /home/cwduffy/kraken_db/virus/ --use-names --threads 56 --report $workingFolder/$k.report.txt --output $workingFolder/$k.kraken $j
	done
	#conda run -n sispa kraken-biom $workingFolder/*report.txt -o $workingFolder/OUTPUT_FP
	# Run the R script on each of the files
	#echo $sampleData $workingFolder
	#conda run -n sispa Rscript diversityPlots.r $workingFolder $sampleData #Removed the use of sample data and the sispa.r script for now due to change in requirements but leaving the code in as it may be useful to add back later. Do need to check that it correctly assigns sample data to the OUTPUT_FP data
	bracken -d /home/cwduffy/kraken_db/virus/ -i $workingFolder/*report.txt -o $workingFolder/$k.bracken -w $workingFolder/$k.bracken.report
	krona
fi

echo $consensus
#Generating consensus sequence - quick method based on max depth, not meant for in depth population studies
if [[ -v consensus ]]; then
	echo "Creating consensus sequence for each sample"
	echo $consensus
	for j in $workingFolder/trimmed*gz; do
		echo $j
		k=$(basename $j)
		k=${k/.fastq.gz/}
		refIndex=$(basename $consensus)
		samtools faidx $consensus
		refIndex=${refIndex/.fasta}
		refIndex=${refIndex/.fa}
		minimap2 -d $workingFolder/$refIndex.mmi $consensus -t 56
		minimap2 $workingFolder/$refIndex.mmi -at 56 $j | samtools view -bT $consensus -@ 56 -o $workingFolder/$k.bam
		samtools sort -@ 56 $workingFolder/$k.bam -o $workingFolder/$k.sorted.bam
		rm -rf $working/$k.bam
		bcftools mpileup -Ou -f $consensus $workingFolder/$k.sorted.bam --threads 56 --annotate FORMAT/AD,INFO/AD | bcftools call -mv -Oz --ploidy 2 --threads 56 > $workingFolder/$k.vcf.gz
		bcftools index $workingFolder/$k.vcf.gz
		bcftools consensus -f $consensus -I --mark-ins lc -o $workingFolder/$k.consensus.fasta $workingFolder/$k.vcf.gz
		Rscript consensus_plots.r
	done
fi


#Need to add check for chimeric reads containing the sispa barcodes.

# Load the data into R and run the analysis there