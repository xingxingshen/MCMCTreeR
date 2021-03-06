#' Estimate Cauchy Distribution for MCMCTree
#'
#' Estimate the offset and scale paramaters of a soft-tailed cauchy distribution and output trees for MCMCTree input
#' @param minAge vector of minimum age bounds for nodes matching order in monoGroups
#' @param maxAge vector of maximum age bounds for nodes matching order in monoGroups
#' @param monoGroups list  with each element containing species that define a node of interest
#' @param phy fully resolved phylogeny in ape format
#' @param offset offset value for cauchy distribution (default = 50) (p in PAML manual page 49)
#' @param scale scale value for cauchy distribution (default = 1.5) (c in PAML manual page 49)
#' @param estimateScale logical specifying whether to estimate scale with a given shape value (default = TRUE)
#' @param minProb probability of left tail (minimum bound) - default to hard minimum (minProb=0)
#' @param maxProb probability of right tail (maximum bound. default = 0.975) 
#' @param plot logical specifying whether to plot to PDF
#' @param pdfOutput pdf output file name
#' @param writeMCMCTree logical whether to write tree in format that is compatible with mcmcTree to file
#' @param mcmcTreeName mcmcTree output file name
#' @keywords 
#' @return list containing node estimates for each distribution
#' \itemize{
#'  \item{"parameters"}{ estimated parameters for each node}
#'  \item{"apePhy"}{ phylogeny in ape format with node labels showing node distributions}
#'  \item{"mcmctree"}{ phylogeny in MCMCTree format}
#'  \item{"nodeLabels"}{ node labels in MCMCTreeR format}
#' }
#' @return If plot=TRUE plot of distributions in file 'pdfOutput' written to current working directory
#' @return If writeMCMCTree=TRUE tree in MCMCTree format in file "mcmcTreeName" written to current working directory
#' @export
#' @examples
#' apeTree <- read.tree(text="((((human, (chimpanzee, bonobo)), gorilla), (orangutan, sumatran)), gibbon);")
#' monophyleticGroups <- list()
#' monophyleticGroups[[1]] <- c("human", "chimpanzee", "bonobo", "gorilla", "sumatran", "orangutan", "gibbon")
#' monophyleticGroups[[2]] <- c("human", "chimpanzee", "bonobo", "gorilla")
#' monophyleticGroups[[3]] <- c("human", "chimpanzee", "bonobo")
#' monophyleticGroups[[4]] <- c("sumatran", "orangutan")
#' minimumTimes <- c("nodeOne"=15, "nodeTwo"=6, "nodeThree"=8, "nodeFour"=13) / 10
#' maximumTimes <- c("nodeOne"=30, "nodeTwo"=12, "nodeThree"=12, "nodeFour"=20) / 10
#' estimateCauchy(minAge=minimumTimes, maxAge=maximumTimes, monoGroups=monophyleticGroups, offset=0.5, phy=apeTree, plot=F)

estimateCauchy <- function(minAge, maxAge, phy, monoGroups, scale=0.2, offset=0.1, estimateScale=T,  minProb=0, maxProb=0.975, plot=FALSE, pdfOutput="cauchyPlot.pdf", writeMCMCTree=FALSE, mcmcTreeName="cauchyInput.tre")	{

	lMin <- length(minAge)
	lMax <- length(maxAge)
	if(lMin != lMax) stop("length of ages do not match")
	if(length(minProb) < lMin) { minProb <- rep_len(minProb, lMin) ; print("warning - minProb parameter value recycled") }
	if(length(maxProb) < lMin) { maxProb <- rep_len(maxProb, lMin) ; print("warning - maxProb parameter value recycled") }
	if(length(offset) < lMin) { offset <- rep_len(offset, lMin) ; print("warning - offset parameter value recycled") }
	if(length(scale) < lMin) { scale <- rep_len(scale, lMin) ; print("warning - scale parameter value recycled") }
	if(length(estimateScale) < lMin) { estimateScale <- rep_len(estimateScale, lMin) ; print("warning - estimateScale argument recycled") }


	nodeFun <- function(x)	{
	
	scaleInt <- scale[x]
	locationInt <- minAge[x]
	offsetInt <- offset[x]
	estimateScaleInt <- estimateScale[x]
	maxProbInt <- maxProb[x]
	minProbInt <- minProb[x]


	if(estimateScaleInt == F) {
			
			scaleInt <- scaleInt ; offsetInt <- offsetInt
			
			} else
			{
			p <- offsetInt
			cEsts <- c()
			cTest <- seq (0.001, 10, by=1e-3)
			for(u in 1:length(cTest)) cEsts[u] = 1 * (minAge[x] + p + cTest[u] * 1/tan((pi * (0.5 + 1/pi * atan(p/cTest[u])) * (1-maxProbInt)/(1 - minProbInt))))
			closest <- which(abs(cEsts-maxAge[x]) == min(abs(cEsts-maxAge[x])))
			upperEst <- cEsts[closest]
			scaleInt <- cTest[closest]
		} 
		
		
	if(minProbInt < 1e-7) minProbInt <- 1e-300
	nodeCon <- paste0("'L[", locationInt, "~", offsetInt, "~", scaleInt, "~",  minProbInt, "]'")	
	parameters <- c(locationInt, offsetInt, scaleInt, minProbInt)
	names(parameters) <- c("tL", "p", "c", "pL")
	return(list(nodeCon, parameters))	
		
	}
		
	
	out <- sapply(1:lMin, nodeFun)
	output <- c()
	prm <- matrix(unlist(out[2,]), ncol=4, byrow=T)
	rownames(prm) <- paste0("node_", 1:lMin)
	colnames(prm) <-  c("tL", "p", "c", "pL")
	output$parameters <- prm
	
	output$apePhy <- nodeToPhy(phy, monoGroups, nodeCon=unlist(out[1,]), T) 
	output$mcmctree <- nodeToPhy(phy, monoGroups, nodeCon=unlist(out[1,]), F) 

	if(writeMCMCTree == T) {
		outputTree <- nodeToPhy(phy, monoGroups, nodeCon=unlist(out[1,]), returnPhy=F) 
		write.table(outputTree, paste0(mcmcTreeName), quote=F, row.names=F, col.names=F)
		}	
	if(plot == T) {
		cat("warning - cauchy plots will be approximations!")
		if(length(list.files(pattern=paste0(pdfOutput))) != 0) {
			cat(paste0("warning - deleting and over-writing file ", pdfOutput))
			file.remove(paste0(pdfOutput))
			}
	 	pdf(paste0(pdfOutput), family="Times")
		for(k in 1:dim(prm)[1]) {
			plotMCMCTree(prm[k,], method="cauchy",  paste0(rownames(prm)[k], " cauchy"), upperTime = max(maxAge)+1)
			}
		dev.off()
		}	
		
	output$nodeLabels <- unlist(out[1,])	
	return(output)
}