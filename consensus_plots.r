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

alldepths=list.files(pattern="depth")
for (i in alldepths){
	data=read.table(i)
	tiff(paste(i,".genomeCov.tiff",sep=""), width=3000, height=2000, units="px",res=300, compression="lzw")
	plot(data$V2, data$V3, cex=0.5, pch=19)
	dev.off()
	tiff(paste(i,".genomeCov.rollmean100.tiff",sep=""), width=3000, height=2000, units="px",res=300, compression="lzw")
	plot(rollmean(data$V3), cex=0.5, pch=19)
	dev.off()
}