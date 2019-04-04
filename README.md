## About

Code and data used for formal analysis in

Lisa Matthias, Najko Jahn, and Mikael Laakso. The Two-Way Street of Open Access Journal Publishing: Flip It and Reverse It. *Publications* 2019, 7(2), 23. <https://doi.org/10.3390/publications7020023>

This formal analysis is written in [R Markdown](http://rmarkdown.rstudio.com/). This
repository contains the datasets used as well as all analytical steps involved.

## Data availability

A dataset that provides data on 152 scholarly journals that have been identified to have "reverse flipped" is made available via Zenodo.

Matthias, Lisa, Jahn, Najko, & Laakso, Mikael. (2019). Reverse flip open access journals [Data set]. *Zenodo*. <http://doi.org/10.5281/zenodo.2553582>

## Generate the paper

Before generating the paper, make sure you have all R packages installed.

To replicate the analytical steps including tables and figures, execute the
article file via the command line interface:

```
Rscript -e "rmarkdown::render('article.Rmd')"
```
