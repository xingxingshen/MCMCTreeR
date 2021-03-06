#' Add Node Constraints to Tree in MCMCTree Format
#'
#' Produce tree with node labels in PAML format
#' @param monoGroups list  with each element containing species that define a node of interest
#' @param phy fully resolved phylogeny in ape format
#' @param nodeCon node distributions in MCMCTreeR format
#' @param returnPhy logical specifying whether to return phy to console or write MCMCTree for input (default = TRUE)
#' @keywords 
#' @return If returnPhy=TRUE phylogeny with node labels in ape format
#' @return If returnPhy=FALSE phylogeny with node labels in MCMCTree format
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
#' boundEst <- estimateBound(minAge=minimumTimes[1], maxAge=maximumTimes[1], monoGroups=monophyleticGroups[[1]], phy=apeTree)
#' nodeToPhy <- function(phy=apeTree, monoGroups=monophyleticGroups[[1]], nodeCon=boundEst$nodeLabels, returnPhy=T)

nodeToPhy <- function(phy, monoGroups, nodeCon, returnPhy=T) {
	
	if(is(monoGroups)[1] != "list") monoGroups <- list(monoGroups)
		
	for(x in 1:length(nodeCon))	{
		#if(length(length(nodeCon)) == 1) phy$node.labels <- rep("", Nnode(phy))
		nodeLocation <- which((Ntip(phy) + 1) : (Ntip(phy) + Nnode(phy)) == commonAnc(phy, tipNames=monoGroups[[x]]))
		phy$node.labels[nodeLocation ] <- nodeCon[x]
	}
	
	if(returnPhy == T) return(phy)
	if(returnPhy == F) {
		s <- write.tree(phy)	
		s <- gsub(")NA", ")", s)
		s <- gsub("\\[", "(", s)
		s <- gsub("\\]", ")", s)
		s <- gsub("~", ",", s)
		names(s) <- NULL
		treeFile <- data.frame(cbind(paste(Ntip(phy), "1"), s, "//end of file"))
		colnames(treeFile) <- rep("", 3)
		return(treeFile)
		}
	}
