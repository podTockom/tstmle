% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/estimate_init_sl3.R
\name{initEst_sl3}
\alias{initEst_sl3}
\title{Initial Estimation with sl3}
\usage{
initEst_sl3(data, fitQ = TRUE, j = 1, folds = NULL,
  fold_fn = "folds_rolling_origin", window = NULL, skip = 0, SL.library)
}
\arguments{
\item{data}{data.frame object containing the time series with relevant time ordering.}

\item{fitQ}{corresponds to the logical TRUE if we are  estimating Q
(conditional density of the outcome). Set to logical FALSE if we are estimating g
(conditional density of the exposure) part of the likelihood.}

\item{j}{size of the artificial batch. This is used in cases where we want to consider
multiple time-point interventions, or when we want to define time as multiple occurences
of A,Y,W nodes. For single time-point interventions default is 1.}

\item{folds}{user-specified list of folds- it should correspond to an element of \code{origami}.
In case it is not specified, it will defined internally.}

\item{fold_fn}{cross-validation scheme, as defined by \code{origami}. See \code{origami::fold_funs}
for detailed explanations. For time-series, implemented cross-validation schemes are
\code{folds_rolling_origin} and \code{folds_rolling_window}.}

\item{window}{in case \code{fold_fn} was set to \code{folds_rolling_window}, specify the
number of observations in each training sample.}

\item{skip}{in case the time-series considered is very long, it is possible there will be many
folds to consider. This parameter allows for few nodes to be skipped. Default is 0, which
corresonds to no nodes skipped.}

\item{SL.library}{list of \code{sl3} algorithms to be used for estimation. For the list of available
learners for time-series, see \code{sl3::sl3_list_learners(c("timeseries"))}.}
}
\value{
An object of class \code{tstmle}.
\describe{
\item{fitW}{Fit object for W part of the likelihood.}
}
}
\description{
This function relies on the stacked ensemble learner in order to estimate relevant
parts of the likelihood as guided by the efficient influence curve. In particular, it
utilizes \code{sl3} package and implemented time-series algorithms in order to
estimate Q and g, without having to specify the fixed dimensional summary measure of the past
or the past window to condition on.
}
