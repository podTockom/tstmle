% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/SI_estimate_tmle.R
\name{SI_update}
\alias{SI_update}
\title{Update function}
\usage{
SI_update(data, Qbounds)
}
\arguments{
\item{data}{\code{data.frame} containing all observed values for the A and Y node,
estimate of g, Q, as well as Q evaluated when A=1 and A=0.}

\item{Qbounds}{bounds for the Q estimates.}
}
\description{
Function to update the Q part of the likelihood using the specified fluctuation model/
}
