% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/spss-reading.R
\name{load.spss}
\alias{load.spss}
\title{Load data from SPSS file}
\usage{
load.spss(x, vars = NULL)
}
\arguments{
\item{x}{a S4 object returned by \code{memisc::spss.system.file}}
}
\value{
Data is returned in a tidy data frame (tibble)
}
\description{
The function returns the actual data set from a SPSS object created by the function \code{\link{memisc::spss.system.file()}}
}
