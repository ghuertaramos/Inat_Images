# Inat_Images
Script to download images from inaturalist.org



1.- Make a species list on a csv file named *species.csv*

![](.\samples\list.png)

2.- Run the script. (You must have R and the *rinat* package installed)

​	`Rscript inat_images.R`



3.- If everything goes well you should have a folder for each species from your list

![](.\samples\folders.png)

4.- Image file names are formatted as follows: `species_user_license_observation.jpeg`

![](.\samples\images.png)

5.- A file *inat_data.csv* with the results of your query will be saved, this files include various information like :species, date, url, coordinates, user, etc.

Notes:

Results per species are limited to 50 images, you can change this parameter on `get_inat_obs()` function

If your query has more than 10 hits, only research grade and an open license images will be downloaded. You can edit this parameter in line 58.



