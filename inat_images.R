#! /usr/bin/Rscript
## Guillermo Huerta Ramos

#this functions makes sure the packages are installed and then loads them
inat_packages <- c("rinat","argparse")
package.check <- lapply(
  inat_packages,
  FUN = function(x) {
    if (!require(x, character.only = TRUE)) {
      install.packages(x, dependencies = TRUE,repos='https://cloud.r-project.org')
      library(x, character.only = TRUE)
    }
  }
)
# library(rinat)
# library(argparse)

#argument configuration
parser <- ArgumentParser()

parser$add_argument("-o", "--observations", default=100,
                    help="The maximum number of results to return [default \"%(default)s\"]")

parser$add_argument("-q", "--quality", default="Research", 
                    help = "Quality grade - Research or All_Q [default \"%(default)s\"]")

parser$add_argument("-l", "--license", default="NonCC", 
                    help = "License type - NonCC, Wikicommons or All_L [default \"%(default)s\"]")

parser$add_argument("-s", "--size", default="Medium",
                    help="Select image size - Small, Medium, Large, Original [default \"%(default)s\"]")

parser$add_argument("-y", "--year", default=NULL,
                    help="Return observations for a given year (can only be one year) [default \"%(default)s\"]")

parser$add_argument("-m", "--month", default=NULL,
                    help="Return observations for a given month, must be numeric, 1-12 [default \"%(default)s\"]")

parser$add_argument("-d", "--day", default=NULL,
                    help="Return observations for a given day of the month, 1-31 [default \"%(default)s\"]")

parser$add_argument("-b", "--bounds", default=NULL,
                    help="A txt file with box of longitude (-180 to 180) and latitude (-90 to 90) see bounds.txt sample [default \"%(default)s\"]")

args <- parser$parse_args()

#create image folder
image_folder <- "./images"
dir.create(image_folder)

# read csv file with species names
obs <- read.csv("./species.csv", header = TRUE)

# Select genus and species columns to create  species query
obs <- as.data.frame(paste(obs$Genus, obs$Species))

## optional functions if your database has any of the following:
# delete empty rows
obs <- obs[!(obs == " "), ]

# delete subspecies since they are not accepted as query (they will be downloaded as descendant taxa)
obs <- sub("^(\\S*\\s+\\S+).*", "\\1", obs)

# delete duplicated names
obs <- unique(obs)

# if argument "bounds" is used the next funcion reads the file
if (!is.null(args$bounds)) {
  bounds <- paste0("./", args$bounds)
  args$bounds <- read.csv(bounds, header= FALSE)
}

#### get image urls and information
inat_data <- sapply(X = obs, FUN = function(x) {
  message(sprintf("Fetching data for %s", x))
  # trycatch function enables to continue the script even if a query doesn't have any hits
  tryCatch(
    {
      # change "maxresults" argument to set the number of images to download
      inat_out <- get_inat_obs(taxon_name = x,
                               maxresults = as.numeric(args$observations),
                               quality = NULL,
                               year = args$year,
                               month = args$month,
                               day = args$day,
                               bounds = args$bounds
                               )
      
      # delay queries 2.5 seconds to avoid server overload error
      Sys.sleep(2.5)
    },
    error = function(e) {
      print(paste0("WARNING:couldn't find a match for ", x))
    }
  )
  
  if (!exists("inat_out")) {
    return(NULL)
  } else {
    return(inat_out)
  }
}, simplify = FALSE)
omit_inat <- sapply(X = inat_data, FUN = is.null)
inat_data <- do.call(rbind, inat_data[!omit_inat])

species <- unique(inat_data$scientific_name)

final_inat_data <- sapply(X = species, FUN = function(x, inat_data, image_folder) {
  newdata <- inat_data[inat_data$scientific_name == x, ]
  
  if (args$quality == "Research") {
    newdata <- newdata[newdata$quality_grade == "research", ]}
  else if (args$quality == "All_Q"){
    newdata <- newdata
  }
  
  if (args$license == "Wikicommons") {
    newdata <- newdata[(newdata$license != "") & (newdata$license != "CC-BY-NC"), ]}
  else if (args$license == "NonCC"){
    newdata <- newdata[newdata$license != "", ]}
  else if (args$license == "All_L"){
    newdata <- newdata
  }
  
  infolder <- paste0(sub(" ", "_", x))
  infolder <- file.path(image_folder, infolder)
  dir.create(infolder, showWarnings = FALSE)
  
  for (b in seq_len(nrow(newdata))) {
    tryCatch(
      {
        user <- newdata[b, ]$user_login
        cc <- newdata[b, ]$license
        # "cc" images are no tagged, this next step includes "CC" on file names
        if (cc == "") {
          cc <- "CC"
        }
        url <- newdata[b, ]$image_url
        id <- newdata[b, ]$id
        
        if (args$size == "Small") {
         url <- sub("medium","small", url)  }
        else if (args$size == "Large") {   
         url <- sub("medium","large", url) }
        else if (args$size == "Original") {   
          url <- sub("medium","original", url) }
        else {url<-url}
        
        file_name <- paste0(x, "_", user, "_", cc, "_", id, ".jpeg")
        file_name <- file.path(infolder, file_name)
        download.file(url, file_name, method = "curl")
      },
      error = function(e) {
        print(paste0("WARNING: couldn't find the url"))
      }
    )
  }
  
  return(newdata)
}, inat_data = inat_data, image_folder = image_folder, simplify = FALSE)
final_inat_data <- do.call(rbind, final_inat_data)

# generate file with inaturalist observations information
write.table(final_inat_data, "./inat_data.csv", row.names = FALSE, sep = "\t")
