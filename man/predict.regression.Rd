% Generated by roxygen2 (4.1.1): do not edit by hand
% Please edit documentation in R/regression.R
\name{predict.regression}
\alias{predict.regression}
\title{Predict method for the regression function}
\usage{
\method{predict}{regression}(object, pred_cmd = "", pred_data = "",
  conf_lev = 0.95, prn = TRUE, ...)
}
\arguments{
\item{object}{Return value from \code{\link{regression}}}

\item{pred_cmd}{Command used to generate data for prediction}

\item{pred_data}{Name of the dataset to use for prediction}

\item{conf_lev}{Confidence level used to estimate confidence intervals (.95 is the default)}

\item{prn}{Print prediction results (default is TRUE)}

\item{...}{further arguments passed to or from other methods}
}
\description{
Predict method for the regression function
}
\details{
See \url{http://vnijs.github.io/radiant/quant/regression.html} for an example in Radiant
}
\examples{
result <- regression("diamonds", "price", c("carat","clarity"))
predict(result, pred_cmd = "carat = 1:10")
predict(result, pred_cmd = "clarity = levels(clarity)")
result <- regression("diamonds", "price", c("carat","clarity"), int_var = c("carat:clarity"))
dpred <<- getdata("diamonds") \%>\% slice(1:10)
predict(result, pred_data = "dpred")
rm(dpred, envir = .GlobalEnv)
}
\seealso{
\code{\link{regression}} to generate the result

\code{\link{summary.regression}} to summarize results

\code{\link{plot.regression}} to plot results
}

