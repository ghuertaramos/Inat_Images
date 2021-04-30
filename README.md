# Inat_Images

#### [![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.4725852.svg)](https://doi.org/10.5281/zenodo.4725852) 

Script to download images from inaturalist.org

1.- Clone this repository using `git clone https://github.com/ghuertaramos/Inat_Images.git` or download directly clicking [here](https://github.com/ghuertaramos/Inat_Images/archive/refs/heads/master.zip)

2.- Make a species list on a csv file named *species.csv* (see the sample file [here](./species.csv))

![](./samples/list.png)

3.- Run the script on the command line. (You must have R and the *rinat* package installed) 

​	You must always provide 3 arguments for your query:

 - `arg 1` = **Maximum number of results**
    - should not be a number higher than 10000, keep in mind this is before filtering 	
 - `arg 2` = **Quality**
    - `Research` - Filters results to download only "ResearchGrade" observations
    - `All_Q`      -  Results include "needs_id" and "casual"  observations
 - `arg 3` =**License type**
    - `Wikicommons` - include only photos with a license acceptable to WikiCommons  (i.e., CC-0, CC-BY, CC-BY-SA). Unfortunately, this filter greatly decreases the amount of pictures you can retrieve since most images are CC-BY-NC
    - `NonCC` - Excludes images with "CC" copyright
    - `All_L`  - Downloads all license types

You could use the following line:

​	`Rscript inat_images.R 2000 Research NonCC`

This would make a query for a maximum of 2000 observations and then filter the results to download only "ResearchGrade" and images without a "CC License"

4.- If everything goes well you should have a folder for each species from your list

![](./samples/folders.png)

5.- Image file names are formatted as follows: `species_user_license_observation-id.jpeg`

![](./samples/images.png)

6.- A file *inat_data.csv* with the results of your query will be saved, this files include various information like :species, date, url, coordinates, user, etc.



# Citations



Guillermo Huerta-Ramos, & Roman Luštrik.  (2021, April 28). ghuertaramos/Inat_Images: v.1 (Version 1.0). Zenodo.  http://doi.org/10.5281/zenodo.4725852

Vijay Barve & Edmund Hart (2014). rinat: Access iNaturalist data through APIs. R package version 0.1.8.



