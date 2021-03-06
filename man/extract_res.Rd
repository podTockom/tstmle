% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/utils.R
\name{extract_res}
\alias{extract_res}
\title{Wrapper for final TMLE results}
\usage{
extract_res(res)
}
\arguments{
\item{res}{results from multiple calls to \code{ruletmle}.}
}
\description{
Function to make extraction of final TMLE results for the optimal individualized
treatment regime parameter more streamlined. In particular, it should provide inference and
results for 4 different scenarious, where the exposure is set to both binary possibilities,
observed exposure, and learner optimal rule.
}
