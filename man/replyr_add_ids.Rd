% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/addIds.R
\name{replyr_add_ids}
\alias{replyr_add_ids}
\title{Add unique ids to rows.  Note: re-arranges rows in many cases.}
\usage{
replyr_add_ids(df, idColName, env = parent.frame(), local_short_cut = TRUE)
}
\arguments{
\item{df}{data.frame object to work with}

\item{idColName}{name of column to add}

\item{env}{environment to evaluate in (not used).}

\item{local_short_cut}{logical, if TRUE use base R on local data.}
}
\description{
Add unique ids to rows.  Note: re-arranges rows in many cases.
}
\examples{

replyr_add_ids(data.frame(x=c('a','b')), 'id', local_short_cut = FALSE)

}
