# SISPA_analysis
 My version of the SISPA analysis. If this works correctly then it should be possible to run the script once and run the entire analysis.
 
 This script assumes that your concatenated fastq files for each experiment are in a single folder. This folder may contain multiple samples, which will be run individually. By default the nanopore software outputs reads in a series of smaller files in a folder called fastq_pass, with one subfolder per barcode. To collect your reads together do the following:
 
 Create a folder where you wish to collect them together using mkdir. I would suggest your home directory. For example, assuming you are in your home directory:
 mkdir experimentName
 cat /home/gary_gridion/runID/fastq_pass/barcodeX/*gz > ~/experimentName/runID_barcodeX.fastq.gz
 
 replacing experimentName, runID and barcodeX with their respecive names.