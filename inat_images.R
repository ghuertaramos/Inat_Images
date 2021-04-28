#! /usr/bin/Rscript
## Guillermo Huerta Ramos

library(rinat)

image_folder <- "./images"
dir.create(image_folder)

# read csv file with species names
obs <- read.csv("./species.csv", header = TRUE)

# Select genus and species columns to creat  species query
obs <- as.data.frame(paste(obs$Genus, obs$Species))

## optional functions if your database has any of the following:
# delete empty rows
obs <- obs[!(obs == " "), ]

# delete subspecies since they are not accepted as query
obs <- sub("^(\\S*\\s+\\S+).*", "\\1", obs)

# delete duplicated accessions
obs <- unique(obs)

#### get image urls and information
inat_data <- sapply(X = obs, FUN = function(x) {
  message(sprintf("Fetching data for %s", x))
  # trycatch function enables to continue the script even if a query doesn't have any hits
  tryCatch(
    {
      # change "maxresults" argument to set the number of images to download
      inat_out <- get_inat_obs(taxon_name = x, maxresults = 50)
      
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
  
  # # this step selects only "research" and open licenses if a species has more than 10 records
  # if (nrow(newdata) > 10) {
  #   newdata <- newdata[newdata$quality_grade == "research", ]
  #   # "cc" images are no tagged, this next step excludes them
  #   newdata <- newdata[newdata$license != "", ]
  # }
  
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
