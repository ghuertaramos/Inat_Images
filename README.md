# Inat_Images

#### [![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.4725852.svg)](https://doi.org/10.5281/zenodo.4725852) 

Script to download images from inaturalist.org

1.- Clone this repository using `git clone https://github.com/ghuertaramos/Inat_Images.git` or download directly clicking [here](https://github.com/ghuertaramos/Inat_Images/archive/refs/heads/master.zip)

2.- Make a species list on a csv file named *species.csv* (see the sample file [here](./species.csv))

![](./samples/list.png)

3.- Run the script on the command line. (You must have R and the *rinat* package installed) 

You must always provide 3 arguments for your query:

 - `arg 1` = **Maximum number of results**
    
    - should not be a number higher than 10000, keep in mind this is before filtering 	
    
      
 - `arg 2` = **Quality**
    - `Research` - Filters results to download only "ResearchGrade" observations
    
    - `All_Q`      -  Results include "Needs_id" and "Casual"  observations
    
      
 - `arg 3` =**License type**
    - `Wikicommons` - include only photos with a license acceptable to WikiCommons  (i.e., CC-0, CC-BY, CC-BY-SA). Unfortunately, this filter greatly decreases the amount of pictures you can retrieve since most images have a "CC-BY-NC" license
    
    - `NonCC` - Excludes images with "CC" copyright
    
    - `All_L`  - Downloads all license types
    
      

You could run something like the following:

	`Rscript inat_images.R 2000 Research NonCC`

This would make a query for a maximum of 2000 observations and then filter the results to download only "ResearchGrade" and images without a "CC" license

[4]().- If everything goes well you should have a folder for each species from your list

![](./samples/folders.png)

5.- Image file names are formatted as follows: `species_user_license_observation-id.jpeg`

![](./samples/images.png)

6.- A file *inat_data.csv* with the results of your query will be saved, this files include various information like :species, date, url, coordinates, user, etc.

# Notes

Depending on the intended use of the images, it is important to be aware of license properties and limitations, some licenses require attribution, asking the original holder for permission to reuse, etc. See [CreativeCommons]( https://creativecommons.org/licenses/?lang=en) and [iNaturalist help page](https://www.inaturalist.org/pages/help)  for more information.

In order to comply with iNaturalist [citation policy](https://www.inaturalist.org/pages/help#cite), it is important to include in your publication some sort of table/appendix with a link to each of the  observations. You could base this table on the *inat_data.csv* output file.

The script has some time restrictions to be able to comply with iNaturalist API query limits:  max of 100 requests per minute,  though it is recommended to reduce usage to 60 requests per minute or lower.  There is a hard limit of 10,000 observations with the iNaturalist API.  Be aware that bulk download may impact severely impact server usage.  Consider supporting [iNaturalist.org](https://www.inaturalist.org/donate?utm_medium=web&utm_source=iNaturalist)

# Citations



Guillermo Huerta-Ramos, & Roman Luštrik.  (2021, April 28). Inat_Images: v.1 (Version 1.0). Zenodo.  http://doi.org/10.5281/zenodo.4725852

Vijay Barve & Edmund Hart (2014). rinat: Access iNaturalist data through APIs. R package version 0.1.8.