% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/cache.R
\docType{methods}
\name{.robustDigest,simList-method}
\alias{.robustDigest,simList-method}
\alias{Cache}
\title{\code{.robustDigest} for \code{simList} class objects}
\usage{
\S4method{.robustDigest}{simList}(object, objects,
  compareRasterFileLength = 1e+06, algo = "xxhash64",
  digestPathContent = FALSE, classOptions = list())
}
\arguments{
\item{object}{an object to digest.}

\item{objects}{Optional character vector indicating which objects are to
be considered while making digestible. This is only relevant
if the object being passed is an environment or list or the like.}

\item{compareRasterFileLength}{Numeric. Optional. When there are Rasters, that
have file-backed storage, this is passed to the length arg in \code{digest}
when determining if the Raster file is already in the database.
Note: uses \code{\link[digest]{digest}} for file-backed Raster.
Default 1e6. Passed to \code{.prepareFileBackedRaster}.}

\item{algo}{The algorithms to be used; currently available choices are
    \code{md5}, which is also the default, \code{sha1}, \code{crc32},
    \code{sha256}, \code{sha512}, \code{xxhash32}, \code{xxhash64} and
    \code{murmur32}.}

\item{digestPathContent}{Logical. Should arguments that are of class \code{Path}
(see examples below) have their name digested
(\code{FALSE}), or their file contents (\code{TRUE}; default).}

\item{classOptions}{Optional list. This will pass into \code{.robustDigest} for
specific classes. Should be options that the \code{.robustDigest} knows what
to do with.}
}
\description{
This is intended to be used within the \code{Cache} function, but can be
used to evaluate what a \code{simList} would look like once it is
converted to a repeatably digestible object.
}
\details{
See \code{\link[reproducible]{robustDigest}}. This method strips out stuff
from a simList class object that would make it otherwise not
reproducibly digestible between sessions, operating systems,
or machines. This will likely still not allow identical digest
results across R versions.
}
\seealso{
\code{\link[reproducible]{robustDigest}}
}
\author{
Eliot Mcintire
}
