# SISPA_analysis
 My version of the SISPA analysis. If this works correctly then it should be possible to run the script once and run the entire analysis.
 
 This script assumes that your concatenated fastq files for each experiment are in a single folder. This folder may contain multiple samples, which will be run individually. By default the nanopore software outputs reads in a series of smaller files in a folder called fastq_pass, with one subfolder per barcode. To collect your reads together do the following:
 
 Create a folder where you wish to collect them together using mkdir. I would suggest your home directory. For example, assuming you are in your home directory:
 mkdir experimentName
 cat /home/gary_gridion/runID/fastq_pass/barcodeX/*gz > ~/experimentName/runID_barcodeX.fastq.gz
 
 replacing experimentName, runID and barcodeX with their respecive names.
 
 Running everything can take a long time so make sure to use tmux to avoid a disconnection.
 
 To run the script use the following command:
 bash sispa.sh -d [directory location]
 
 If run like this then the script will trim the sequences but that's it. To run the individual analysis use one of the following additional options:
 -5 [value] - number of bases to trim from the 5' end of each read. Default 18
 -3 [value] - number of bases to trim from the 3' end of each read. Default 18
 -k - run Kraken metagenomics analysis
 -c [reference file] - generate a consensus sequence for each sample with IUPAC ambiguity codes for heterozygous bases. Indels will only be inserted if they are the dominant (frequency >50%). This will also create 2 coverage plots for each sample, the first is simple coverage at each base, the second is a rolling average over 100bp.