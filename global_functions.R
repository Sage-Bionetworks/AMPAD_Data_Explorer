library(memoise)

#for faster rendering caching the computationally expensive functions
memoised_corAndPvalue <- memoise(function(...) corAndPvalue(...))

output_download_data <- function(mat, file) {  
  df <- cbind(data.frame(ID=rownames(mat)),
              as.data.frame(mat))
  write.csv(df, file, row.names=F, col.names=T)
}

get_eset_withcorrelated_genes <- function(geneIds, eset, corThreshold, corDirection='both'){
  
  expMatrix <- exprs(eset)
  flog.debug('Calculating correlated genes ....', name="server")

  #expression matrix with selected genes
  m1 <- expMatrix[rownames(expMatrix) %in% geneIds,]
  
  #expression matrix with which the selected genes will be correlated
  m2 <- expMatrix
  
  #calculate correlation
  res <- memoised_corAndPvalue(t(m1),t(m2),nThreads=4)
  cor <- round(res$cor,digits=3)
  
  # Force threshold to be positive, so not confused by negative values
  corThreshold <- abs(corThreshold)
  
  # Subset based on direction
  if (corDirection == 'positive') {
    cor <- cor >= corThreshold
  }
  else if (corDirection == 'negative') {
    cor <- cor <= -corThreshold
  }
  else if (corDirection == 'both') {
    cor <- abs(cor) >= corThreshold
  }
  else {
    cor <- abs(cor) >= corThreshold
  }
  
  #columns of the cor matrix which have correlation with some gene > corThreshold
  cols_to_select <- apply(cor,2,any)
  correlated_genes <- union(colnames(cor)[cols_to_select], rownames(m1))
  
  flog.debug('Done calculating correlated genes', name="server")
  
  eset[rownames(expMatrix) %in% correlated_genes,]
}

get_expMatrix_withcorrelated_genes <- function(geneIds, expMatrix, corThreshold, corDirection='both'){
  cat('Calculating correlated genes ....')  
  #expression matrix with selected genes
  m1 <- expMatrix[rownames(expMatrix) %in%  geneIds,]
  #expression matrix with which the selected genes will be correlated
  m2 <- expMatrix
  #calculate correlation
  res <- memoised_corAndPvalue(t(m1),t(m2),nThreads=4)
  cor <- round(res$cor,digits=3)
  
  # Force threshold to be positive, so not confused by negative values
  corThreshold <- abs(corThreshold)

  # Subset based on direction
  if (corDirection == 'positive') {
    cor <- cor >= corThreshold
  }
  else if (corDirection == 'negative') {
    cor <- cor <= -corThreshold
  }
  else if (corDirection == 'both') {
    cor <- abs(cor) >= corThreshold
  }
  else {
    cor <- abs(cor) >= corThreshold
  }
  
  #columns of the cor matrix which have correlation with some gene > corThreshold
  cols_to_select <- apply(cor,2,any)
  correlated_genes <- union(colnames(cor)[cols_to_select], rownames(m1))
  cat('Done','\n')
  expMatrix[rownames(expMatrix) %in% correlated_genes,]
}


#filter metadata
get_filtered_metadata <- function(input, metadata){
  filtered_metadata <- metadata
  
  if( length(input$DataSetName) != 0 ){
    filtered_metadata <- subset(filtered_metadata, DataSetName %in% input$DataSetName)
  }
 
  filtered_metadata
}

filter_by_metadata <- function(input, eset){
  filtered_metadata <- pData(eset)
  
  if( length(input$Study) != 0 ){
    filtered_metadata <- subset(filtered_metadata, Study %in% input$Study)
  }
  if( length(input$BrainRegion) != 0 ){
    filtered_metadata <- subset(filtered_metadata, BrainRegion %in% input$BrainRegion)
  }
  if( length(input$Status) != 0 ){
    filtered_metadata <- subset(filtered_metadata, Status %in% input$Status)
  }
  if( length(input$Gender) != 0 ){
    filtered_metadata <- subset(filtered_metadata, Gender %in% input$Gender)
  }

  eset[, rownames(filtered_metadata)]
}


#create the annotation data frame for the heatmap
get_filteredAnnotation <- function(input,metadata){
  if(length(input$heatmap_annotation_labels) == 0){
    stop('please select at least one heatmap annotation variable \n\n')      
  }
  else{
    annotation <- metadata[,c(input$heatmap_annotation_labels),drop=F]
    # rownames(annotation) <- metadata$Sample
    annotation
  }
}

get_heatmapAnnotation <- function(heatmap_annotation_labels, metadata){
  if(length(heatmap_annotation_labels) == 0){
    stop('please select at least one heatmap annotation variable \n\n')      
  }
  else{
    annotation <- metadata[, heatmap_annotation_labels, drop=F]
    annotation
  }
}

clean_list <- function(x, change_case=toupper) {
  # Split by space, comma or new lines
  x <- unlist(strsplit(x, split=c('[\\s+,\\n+\\r+)]'),perl=T))
  
  # convert everything to specified case
  x <- change_case(x)
  
  # remove the blank entries
  x <- x[!(x == "")]
  
  x
}

