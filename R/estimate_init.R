#' Initial Estimation with sl3 and specified C_{o(t)} dimension
#'
#' This function relies on the stacked ensemble learner in order to estimate relevant
#' parts of the likelihood as guided by the efficient influence curve.
#' (best used for short-term dependence).
#'
#' @param Y data.frame object containing the outcome variable.
#' @param X data.frame object containing the relevant covariates.
#' @param folds user-specified list of folds- it should correspond to an element of \code{origami}.
#' @param SL.library list of \code{sl3} algorithms to be used for estimation.
#'
#'
#' @return An object of class \code{tstmle}.
#' \describe{
#' \item{cvRisk}{CV Risk for each algorithm and Super Learner.}
#' \item{valY}{Prediction based on the estimated SL fit.}
#' \item{SL.library}{list of \code{sl3} algorithms to be used for estimation.}
#' \item{folds}{user-specified list of folds- it should correspond to an element of \code{origami}.}
#' \item{fullFit}{Fit on all samples.}
#' \item{ccvFit}{CV fit.}
#' }
#'
#' @importFrom sl3 make_sl3_Task
#'
#' @export
#

initEst <- function(Y, X, folds=NULL,SL.library) {

  covars<-names(X)
  outcome<-names(Y)
  data<-cbind.data.frame(Y,X)

  #Create sl3 task:
  #TO DO: add option for weights
  task <- sl3::make_sl3_Task(data, covariates = covars, outcome = outcome,
                             outcome_type=NULL, folds=folds)

  #Return sl3 trained object:
  sl3_fit<-sl3.fit(task=task,SL.library=SL.library)

  out <- list(cvRisk = sl3_fit$risk, valY = sl3_fit$pred, SL.library = SL.library, folds = folds,
              fullFit = sl3_fit$sl.fit, cvFit=sl3_fit$cv.fit)

  class(out) <- c("initEst", "sl3")

  return(out)

}

#' Make initial dataframe
#'
#' Function to create the initial data.frame \code{sl3} would expect with i.i.d data.
#'
#' @param data data.frame object containing the time series with relevant time ordering.
#' @param Cy numeric specifying possible Markov order for Y nodes.
#' @param Ca numeric specifying possible Markov order for A nodes.
#'
#' @return An object of class \code{tstmle}.
#' \describe{
#' \item{Y}{Observed outcome with relevant lagged time-points as specified by Cy.}
#' \item{A}{FObserved exposure with relevant lagged time-points as specified by Ca.}
#' \item{Ca}{Input Markov order for A.}
#' \item{Cy}{Input Markov order for Y.}
#' \item{data}{Input data.}
#' }
#'
#' @importFrom Hmisc Lag
#' @importFrom stats complete.cases
#'
#' @export
#

initFrame <- function(data, Cy, Ca){

  # How many in a batch:
  step <- length(grep("_1$", row.names(data), value = TRUE))
  name<-row.names(data)

  # Lag past
  res_y <- lapply(seq_len(Cy), function(x) {
    Hmisc::Lag(data[, 1], x)
  })
  res_a <- lapply(seq_len(Ca), function(x) {
    Hmisc::Lag(data[, 1], x)
  })

  res_y <- data.frame(matrix(unlist(res_y), nrow = length(res_y[[1]])),
                    stringsAsFactors = FALSE)
  res_a <- data.frame(matrix(unlist(res_a), nrow = length(res_a[[1]])),
                      stringsAsFactors = FALSE)

  data_full_y <- cbind.data.frame(data = data, res_y)
  data_full_a <- cbind.data.frame(data = data, res_a)

  #Start will depend on values of Cy and Ca.
  #Keep only samples that have full history
  cc <- stats::complete.cases(data_full_y)
  data_full_y <- data_full_y[cc, ]

  cc <- stats::complete.cases(data_full_a)
  data_full_a <- data_full_a[cc, ]

  #Separate by process:
  Y <- data_full_y[grep("Y", row.names(data_full_y), value = TRUE), ]
  A <- data_full_a[grep("A", row.names(data_full_a), value = TRUE), ]

  #Shorten the longer one if not equal:
  if(nrow(Y) != nrow(A)){

    warning("Note that having different dimensions of Cy and Ca will result in a smaller n here.")

    if(nrow(Y) < nrow(A)){
      A<-A[(nrow(A)-nrow(Y)+1):nrow(A),]
    }else if(nrow(Y) > nrow(A)){
      Y<-Y[(nrow(Y)-nrow(A)+1):nrow(Y),]
    }

  }

  names(Y)[2:ncol(Y)]<-name[Cy:1]
  names(Y)[1:2]<-c("Y","A")

  names(A)[2:ncol(A)]<-name[Ca:1]
  names(A)[1]<-c("A")

  row.names(Y)<-NULL
  row.names(A)<-NULL

  out <- list(Y = Y, A = A, Cy=Cy, Ca=Ca, data=data)
  return(out)

}

#' Fit Q with specified exposure
#'
#' Function to make estimation of Q with specified exposure easier.
#'
#' @param data data.frame object containing the time series with relevant time ordering.
#' @param fit fit object from \code{initEst}.
#' @param setA specify the value each A node should be set to.
#'
#' @return An object of class \code{tstmle}.
#' \describe{
#' \item{valY}{Prediction based on the input \code{fit} object.}
#' }
#'
#' @importFrom sl3 make_sl3_Task
#'
#' @export
#'

initEst_setA<-function(data, fit, setA){

  data_setA<-data

  #Set A node to specified intervention:
  data_setA[,"A"] = setA

  covars<-names(data_setA[,-1])
  outcome<-names(data_setA[,1])

  #Create sl3 task:
  #TO DO: add option for weights
  task_setA <- sl3::make_sl3_Task(data_setA, covariates = covars, outcome = outcome,
                                  outcome_type=NULL, folds=fit$folds)

  sl_preds <- fit$fullFit$predict(task_setA)

  out <- list(valY = sl_preds)

  return(out)

}

#' Split-specific predictions
#'
#' Function to estimate split-specific predictions for Q and g, and relevant parts for the
#' optimal treatment regime.
#'
#' @param fold one of the folds from the folds object.
#' @param data data.frame object containing the time series with relevant time ordering.
#' @param estQ object of class \code{initEst} with \code{sl3} results for Q.
#' @param estg object of class \code{initEst} with \code{sl3} results for g.
#'
#' @return An object of class \code{tstmle}.
#' \describe{
#' \item{QAW}{Split-specific prediction of Q.}
#' \item{Q1W}{Split-specific prediction of Q(1,W).}
#' \item{Q0W}{Split-specific prediction of Q(0,W).}
#' \item{pA1}{Split-specific prediction of g.}
#' \item{B}{Split-specific prediction of the blip.}
#' \item{Rule}{Split-specific prediction of the maximizing rule.}
#' \item{K}{Split-specific absolute value of the blip.}
#' }
#'
#' @importFrom sl3 make_sl3_Task
#'
#' @export
#'

cv_split <- function(fold, data, estQ, estg){

  #Get fold index
  v <- fold_index()

  #Get the coefficients:
  coef<-estQ$fullFit$coefficients
  coefg<-estg$fullFit$coefficients

  #Get split-specific fits:
  splitQ <- estQ$cvFit[[v]]
  splitg <- estg$cvFit[[v]]

  #Predict on all the data:
  new_folds<-make_folds(data, fold_fun = folds_resubstitution)[[1]]

  #QAW
  covars<-names(data[,-1])
  outcome<-names(data[,1])

  task<-sl3::make_sl3_Task(data, covariates = covars, outcome = outcome,
                           outcome_type=NULL, folds=new_folds)
  QAW <- as.matrix(splitQ$predict(task)) %*% as.matrix(coef)

  #Q1W:
  new_data<-data
  new_data[,"A"] = 1

  task<-sl3::make_sl3_Task(new_data, covariates = covars, outcome = outcome,
                           outcome_type=NULL, folds=new_folds)
  Q1W <- as.matrix(splitQ$predict(task)) %*% as.matrix(coef)

  #Q0W:
  new_data<-data
  new_data[,"A"] = 0

  task<-sl3::make_sl3_Task(new_data, covariates = covars, outcome = outcome,
                           outcome_type=NULL, folds=new_folds)
  Q0W <- as.matrix(splitQ$predict(task)) %*% as.matrix(coef)

  #p1A:
  covars<-names(data[,c(-1,-2)])
  outcome<-names(data[,2])

  task<-sl3::make_sl3_Task(data, covariates = covars, outcome = outcome,
                           outcome_type=NULL, folds=new_folds)
  pA1 <- as.matrix(splitg$predict(task)) %*% as.matrix(coefg)

  #Blip
  A<-data$A
  Y<-data$Y

  B <- (A/pA1 - (1 - A)/(1 - pA1)) * (Y - QAW) + Q1W - Q0W

  #Maximize:
  Rule <- as.numeric(B > 0)

  K <- as.vector(abs(B))

  return(list(QAW = QAW, Q1W = Q1W, Q0W = Q0W, pA1 = pA1, B = B, Rule = Rule, K = K))

}


