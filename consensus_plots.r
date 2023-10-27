args=commandArgs(trailingOnly=TRUE)

currwf=args[1]

required_packages=c("zoo")

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

print(currwf)

alldepths=list.files(currwf, pattern="depth")
print(alldepths)
for (i in alldepths){
	data=read.table(paste(currwf,"/",i,sep=""))
	tiff(paste(currwf,"/",i,".genomeCov.tiff",sep=""), width=3000, height=2000, units="px",res=300, compression="lzw")
	plot(data$V2, data$V3, cex=0.5, pch=19)
	dev.off()
	print("a")
	tiff(paste(currwf,"/",i,".genomeCov.rollmean100.tiff",sep=""), width=3000, height=2000, units="px",res=300, compression="lzw")
	plot(rollmean(data$V3, 100), cex=0.5, pch=19)
	dev.off()
	print("b")
}