## About

Code and data used for formal analysis in

Lisa Matthias, Najko Jahn, and Mikael Laakso. The Two-Way Street of Open Access Journal Publishing: Flip It and Reverse It. Submitted to *Publications*.

This formal analysis is written in [R Markdown](http://rmarkdown.rstudio.com/). This
repository contains the datasets used as well as all analytical steps involved.

## Generate the paper

Before generating the paper, make sure you have all R packages installed.

To replicate the analytical steps including tables and figures, execute the
article file via the command line interface:

```
Rscript -e "rmarkdown::render('article.Rmd')"
```