% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/plotting-diagrams.R
\docType{methods}
\name{objectDiagram}
\alias{objectDiagram}
\alias{objectDiagram,simList-method}
\title{Simulation object dependency diagram}
\usage{
objectDiagram(sim, ...)

\S4method{objectDiagram}{simList}(sim, ...)
}
\arguments{
\item{sim}{A \code{simList} object (typically corresponding to a
completed simulation).}

\item{...}{Additional arguments passed to \code{mermaid}.
Useful for specifying \code{height} and \code{width}.}
}
\value{
Plots a sequence diagram, invisibly returning a \code{mermaid} object.
}
\description{
Create a sequence diagram illustrating the data object dependencies of a
simulation. Offers a more detailed view of specific objects than does
plotting the \code{depsEdgeList} directly with \code{\link{moduleDiagram}}.
}
\seealso{
\code{\link[DiagrammeR]{mermaid}}.
}
\author{
Alex Chubaty
}
