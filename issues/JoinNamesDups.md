<!-- Generated from .Rmd. Please edit that file -->
Duplicate columns not allowed in join
-------------------------------------

Instead of adding suffixes join fails with duplicate column message. I think this depends on the version of dplyr used. Seeing the failure with the dev-version of dplyr '0.5.0.9004' as of 5-14-2017.  Confirmed it works properly for dplyr 0.5.0.

Submitted as [`Sparklyr` issue 677](https://github.com/rstudio/sparklyr/issues/677) and [`dplyr` issue 2774](https://github.com/tidyverse/dplyr/issues/2774).

``` r
# devtools::install_github("tidyverse/dplyr")
# devtools::install_github('tidyverse/dbplyr')
suppressPackageStartupMessages(library('dplyr'))
packageVersion("dplyr")
```

    ## [1] '0.5.0.9004'

``` r
library('sparklyr')
packageVersion("sparklyr")
```

    ## [1] '0.5.4'

``` r
if(requireNamespace("dbplyr", quietly = TRUE)) {
  packageVersion("dbplyr")
}
```

    ## [1] '0.0.0.9001'

``` r
R.Version()$version.string
```

    ## [1] "R version 3.4.0 (2017-04-21)"

``` r
sc <- sparklyr::spark_connect(version='2.0.2', 
   master = "local")
d1 <- copy_to(sc, data.frame(x=1:3, y=4:6), 'd1')
d2 <- copy_to(sc, data.frame(x=1:3, y=7:9), 'd2')

left_join(d1, d2, by='x')
```

    ## Source:     lazy query [?? x 3]
    ## Database:   spark_connection

    ## Error: Each variable must have a unique name.
    ## Problem variables: 'y'

``` r
spark_disconnect(sc)
rm(list=ls())
gc(verbose = FALSE)
```

    ##           used (Mb) gc trigger (Mb) max used (Mb)
    ## Ncells  673696 36.0    1168576 62.5  1168576 62.5
    ## Vcells 1160680  8.9    2060183 15.8  1372249 10.5
