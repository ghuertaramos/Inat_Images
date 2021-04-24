#! /usr/bin/Rscript
## Guillermo Huerta Ramos

# start with a new environment
rm(list = ls())

# install.packages('rinat')
library(rinat)

# read csv file with species names
obs <- read.csv("./species.csv", header=T)

# Select genus and species columns to creat  species query
obs <- as.data.frame(paste(obs$Genus, obs$Species))


## optional functions if your database has any of the following:
# delete empty rows
obs <- obs[!(obs==" "), ]

# delete subspecies since they are not accepted as query
obs <- sub("^(\\S*\\s+\\S+).*", "\\1", obs)

# delete duplicated accessions
obs <- unique(obs)

# create empty data frame to populate with inat information
inat_data <- data.frame(matrix(ncol = 36, nrow = 0))

dir.create("./images")
setwd("./images")

#### get image urls and information

for (i in obs) {
  #trycatch function enables to continue the script even if a query doesn't have any hits
  tryCatch({

#change "maxresults" argument to set the number of images to download
inat_out <- get_inat_obs(taxon_name = i, maxresults = 50)

inat_data  <- rbind(inat_data, inat_out)
#delay queries 2.5 seconds to avoid server overload error
Sys.sleep(2.5)

  }, error=function(e){print(paste0("WARNING:couldn't find a match for ", i))})
}


species  <- unique(inat_data$scientific_name)

final_inat_data <- data.frame(matrix(ncol = 36, nrow = 0))

for (i in species){
newdata <- subset(inat_data, scientific_name == i)

#this step selects only "research" and open licenses if a species has more than 10 records 
if (nrow(newdata) > 10){

newdata <- subset(newdata, quality_grade == "research" )
newdata <- subset(newdata, license != "CC")

final_inat_data  <- rbind(final_inat_data, newdata)
} else{
  final_inat_data  <- rbind(final_inat_data, newdata)
}

infolder <- paste0(sub(" ", "_", i))
dir.create(infolder)
setwd(infolder)

for (b in seq(nrow(newdata))){
  tryCatch({
  user<-newdata[b,11]
  cc<-newdata[b,33]
  #for some reason "cc" images are no tagged, this next step includes "CC" on file names
    if (cc==""){
        cc<-"CC"
    }
  url<-newdata[b,10]
  id<-newdata[b,12]
  file_name<- paste0(infolder,"_",user,"_",cc,"_",id,".jpeg")
  download.file(url, file_name, method = "curl")
  }, error=function(e){print(paste0("WARNING:couldn't find the url"))})
}
setwd("../")

}
setwd("../")
#generate file with inaturalist observations information
write.csv(final_inat_data, "./inat_data.csv", row.names = F)
