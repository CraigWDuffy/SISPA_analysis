#Haven't tested this yet

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


library("phyloseq")
library(ggplot2)
library(biomformat)
library(dplyr)
library(RColorBrewer)
library(vegan)
library("DESeq2")
library(scales)

sample_data <- read.csv("sample_data.csv")
row.names(sample_data) <- sample_data$X
sample_data <- sample_data %>% select (-X) 
data<-import_biom("OUTPUT_FP", parseFunction=parse_taxonomy_default)
sample_data <-sample_data(sample_data)
merged <- merge_phyloseq(data, sample_data)
sample_sums(data)

rarecurve(t(otu_table(data)), step=50, cex=0.5)
data.rarefied = rarefy_even_depth(data, rngseed=1, sample.size=0.9*min(sample_sums(data)), replace=F)
rarecurve(t(otu_table(data.rarefied)), step=50, cex=0.5)

merged.rarefied <- merge_phyloseq(data.rarefied, sample_data)
sample_sums(data.rarefied)

plot_richness(data.rarefied, measures=c("Observed","Chao1", "Shannon"))+ #stat_ellipse()+ geom_boxplot(varwidth = TRUE, alpha = 0.5, position = "dodge2")+ theme_classic()+ theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.5))+ xlab("")

ps.phylum = tax_glom(data, taxrank="Rank2", NArm=FALSE)
plot_bar(ps.phylum, fill="Rank2")

top50 <- names(sort(taxa_sums(data), decreasing=TRUE))[1:50]
ps.top50 <- transform_sample_counts(data, function(OTU) OTU/sum(OTU))
ps.top50 <- prune_taxa(top50, ps.top50)
top20 <- names(sort(taxa_sums(data), decreasing=TRUE))[1:20]
ps.top20 <- transform_sample_counts(data, function(OTU) OTU/sum(OTU))
ps.top20 <- prune_taxa(top20, ps.top20)
plot_bar(ps.top50, fill = "Rank6")