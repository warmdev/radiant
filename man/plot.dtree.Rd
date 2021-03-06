% Generated by roxygen2 (4.1.1): do not edit by hand
% Please edit documentation in R/dtree.R
\name{plot.dtree}
\alias{plot.dtree}
\title{Plot method for the dtree function}
\usage{
\method{plot}{dtree}(x, final = FALSE, shiny = FALSE, ...)
}
\arguments{
\item{x}{Return value from \code{\link{dtree}}}

\item{final}{If TRUE plot the decision tree solution, else the initial decision tree}

\item{shiny}{Did the function call originate inside a shiny app}

\item{...}{further arguments passed to or from other methods}
}
\description{
Plot method for the dtree function
}
\details{
See \url{http://vnijs.github.io/radiant/quant/dtree.html} for an example in Radiant
}
\seealso{
\code{\link{dtree}} to generate the result

\code{\link{summary.dtree}} to summarize results
}

