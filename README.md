# Inat_Images


You can now cite the code using the following:

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.4725851.svg)](https://doi.org/10.5281/zenodo.4725851)

Script to download images from inaturalist.org

1.- Make a species list on a csv file named *species.csv*

![](./samples/list.png)

2.- Run the script. (You must have R and the *rinat* package installed) 

​	You must always provide 3 arguments for your query:

 - `arg 1` = Maximum number of results
    - should not be a number higher than 10000, keep in mind this is before filtering 	
 - `arg 2` = Quality
    - **Research** - Filters results to download only "ResearchGrade" observations
    - **All_Q**      -  Results include "needs_id" and "casual"  observations
 - `arg 3` =License type
    - **Wikicommons** - include only photos with a license acceptable to WikiCommons  (i.e., CC-0, CC-BY, CC-BY-SA). Unfortunately, this filter greatly decreases the amount of pictures you can retrieve since most images are CC-BY-NC
    - **NonCC** - Excludes images with copyright "CC"
    - **All_L**  - Downloads all types of licenses

From command line you could run the following:

​	`Rscript inat_images.R 2000 Research NonCC`

This would make a query for a maximum of 2000 observations and then filter the results to download only "ResearchGrade" and images without a "CC License"

3.- If everything goes well you should have a folder for each species from your list

![](./samples/folders.png)

4.- Image file names are formatted as follows: `species_user_license_observation.jpeg`

![](./samples/images.png)

5.- A file *inat_data.csv* with the results of your query will be saved, this files include various information like :species, date, url, coordinates, user, etc.



