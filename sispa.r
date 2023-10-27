#Haven't tested this yet

args=commandArgs(trailingOnly=TRUE)

currwf=args[1]
sampleData=args[2]

required_packages=c("phyloseq","ggplot2","biomformat","dplyr","RColorBrewer","vegan","DESeq2","scales")

for (currPack in required_packages){
	installed=require(eval(currPack), character.only=T)
	if (!installed){
		if (currPack %in% rownames(available.packages())){
			install.packages(eval(currPack))
		} else {
			if (!require("BiocManager", quietly = TRUE)){
				install.packages("BiocManager")
			}
			BiocManager::install(eval(currPack))
		}
	}
}

for (currPack in required_packages){
	library(eval(currPack), character.only=T)
}

print(sampleData)
print(currwf)

sample_data <- read.csv(sampleData,row.names=1)
data<-import_biom(paste(currwf,"/OUTPUT_FP",sep=""), parseFunction=parse_taxonomy_default)
sample_data <-sample_data(sample_data)
merged <- merge_phyloseq(data, sample_data)

tiff(paste(currwf,"/richness.tiff",sep=""),width=3000, height=1500, units="px",res=300, compression="lzw")
plot_richness(merged, measures=c("Observed","Chao1", "Shannon")) #+ stat_ellipse()+ geom_boxplot(varwidth = TRUE, alpha = 0.5, position = "dodge2")+ theme_classic()+ theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.5))+ xlab("")
dev.off()

tiff(paste(currwf,"/all_phyla.tiff",sep=""),width=3000, height=1500, units="px",res=300, compression="lzw")
ps.phylum = tax_glom(merged, taxrank="Rank2", NArm=FALSE)
plot_bar(ps.phylum, fill="Rank2")
dev.off()

top50 <- names(sort(taxa_sums(merged), decreasing=TRUE))[1:50]
ps.top50 <- transform_sample_counts(merged, function(OTU) OTU/sum(OTU))
ps.top50 <- prune_taxa(top50, ps.top50)
tiff(paste(currwf,"/top50_genus.tiff",sep=""),width=3000, height=1500, units="px",res=300, compression="lzw")
plot_bar(ps.top50, fill = "Rank6")
dev.off()

top20 <- names(sort(taxa_sums(merged), decreasing=TRUE))[1:20]
ps.top20 <- transform_sample_counts(merged, function(OTU) OTU/sum(OTU))
ps.top20 <- prune_taxa(top20, ps.top20)
tiff(paste(currwf,"/top20_genus.tiff",sep=""),width=3000, height=1500, units="px",res=300, compression="lzw")
plot_bar(ps.top20, fill = "Rank6")
dev.off()

write.csv(merged@otu_table, paste(currwf,"/all_taxaID_proportions.csv",sep=""), row.names=T)
write.csv(ps.top50@otu_table, paste(currwf,"/top50_taxaID_proportions.csv",sep=""), row.names=T)
write.csv(ps.top20@otu_table, paste(currwf,"/top20_taxaID_proportions.csv",sep=""), row.names=T)
write.table(tax_table(merged), paste(currwf,"/all_taxaID_to_names.txt",sep=""), row.names=T, col.names=T)
write.table(tax_table(ps.top50), paste(currwf,"/top50_taxaID_to_names.txt",sep=""), row.names=T, col.names=T)
write.table(tax_table(ps.top20), paste(currwf,"/top20_taxaID_to_names.txt",sep=""), row.names=T, col.names=T)