if (getRversion() >= "3.1.0") {
  utils::globalVariables(".")
}

################################################################################
#' Initialize a new simulation
#'
#' Create a new simulation object, the "sim" object. This object is implemented
#' using an \code{environment} where all objects and functions are placed.
#' Since environments in \code{R} are
#' pass by reference, "putting" objects in the sim object does no actual copy. The
#' \code{simList} also stores all parameters,
#' and other important simulation information, such
#' as times, paths, modules, and module load order. See more details below.
#'
#' \subsection{Calling this \code{simInit} function does the following:}{
#'   \tabular{lll}{
#'   \bold{What} \tab \bold{Details} \tab \bold{Argument(s) to use} \cr
#'   fills \code{simList} slots \tab places the arguments \code{times},
#'     \code{params}, \code{modules}, \code{paths} into equivalently named
#'     \code{simList} slots \tab \code{times},
#'     \code{params}, \code{modules}, \code{paths}\cr
#'   sources all module files \tab places all function definitions in the
#'     \code{simList}, specifically, into a sub-environment of the main
#'     \code{simList} environment: e.g., \code{sim$<moduleName>$function1}
#'     (see section on \bold{Scoping}) \tab \code{modules} \cr
#'   copies objects \tab from the global environment to the
#'     \code{simList} environment \tab \code{objects} \cr
#'   loads objects \tab from disk into the \code{simList} \tab \code{inputs} \cr
#'   schedule object loading/copying \tab Objects can be loaded into the
#'     \code{simList} at any time during a simulation  \tab \code{inputs} \cr
#'   schedule object saving \tab Objects can be saved to disk at any arbitrary
#'     time during the simulation. If specified here, this will be in addition
#'     to any saving due code inside a module (i.e., a module may manually
#'     run \code{write.table(...)} \tab \code{outputs} \cr
#'   schedules "init" events \tab from all modules (see \code{\link{events}})
#'        \tab automatic  \cr
#'   assesses module dependencies \tab via the inputs and outputs identified in their
#'     metadata. This gives the order of the \code{.inputObjects} and \code{init}
#'     events. This can be overridden by \code{loadOrder}. \tab automatic \cr
#'   determines time unit \tab takes time units of modules
#'       and how they fit together \tab \code{times} or automatic \cr
#'   runs \code{.inputObjects} functions \tab from every module
#'     \emph{in the module order as determined above} \tab automatic
#'   }
#' }
#'
#' \code{params} can only contain updates to any parameters that are defined in
#' the metadata of modules. Take the example of a module named, \code{Fire}, which
#' has a parameter named \code{.plotInitialTime}. In the metadata of that module,
#' it says \code{TRUE}. Here we can override that default with:
#' \code{list(Fire=list(.plotInitialTime=NA))}, effectively turning off plotting. Since
#' this is a list of lists, one can override the module defaults for multiple parameters
#' from multiple modules all at once, with say:
#' \code{list(Fire = list(.plotInitialTime = NA, .plotInterval = 2),
#'            caribouModule = list(N = 1000))}.
#'
#' We implement a discrete event simulation in a more modular fashion so it is
#' easier to add modules to the simulation. We use S4 classes and methods,
#' and use \code{data.table} instead of \code{data.frame} to implement the event
#' queue (because it is much faster).
#'
#' \code{paths} specifies the location of the module source files,
#' the data input files, and the saving output files. If no paths are specified
#' the defaults are as follows:
#'
#' \itemize{
#'   \item \code{cachePath}: \code{getOption("spades.cachePath")};
#'
#'   \item \code{inputPath}: \code{getOption("spades.modulePath")};
#'
#'   \item \code{modulePath}: \code{getOption("spades.inputPath")};
#'
#'   \item \code{inputPath}: \code{getOption("spades.outputPath")}.
#' }
#'
#' @section Caching:
#'
#' Using caching with \code{SpaDES} is vital when building re-useable and reproducible
#' content. Please see the vignette dedicated to this topic. See
#' \url{https://CRAN.R-project.org/package=SpaDES/vignettes/iii-cache.html}
#'
#' @note
#' The user can opt to run a simpler \code{simInit} call without inputs, outputs, and times.
#' These can be added later with the accessor methods (See example). These are not required for initializing the
#' simulation via simInit. \code{modules}, \code{paths}, \code{params}, and \code{objects}
#' are all needed for successful initialization.
#'
#' @param times A named list of numeric simulation start and end times
#'        (e.g., \code{times = list(start = 0.0, end = 10.0)}).
#'
#' @param params A list of lists of the form list(moduleName=list(param1=value, param2=value)).
#' See details.
#'
#' @param modules A named list of character strings specifying the names
#' of modules to be loaded for the simulation. Note: the module name
#' should correspond to the R source file from which the module is loaded.
#' Example: a module named "caribou" will be sourced form the file
#' \file{caribou.R}, located at the specified \code{modulePath(simList)} (see below).
#'
#' @param objects (optional) A vector of object names (naming objects
#'                that are in the calling environment of
#'                the \code{simInit}, which is often the
#'                \code{.GlobalEnv} unless used programmatically
#'                -- NOTE: this mechanism will
#'                fail if object name is in a package dependency), or
#'                a named list of data objects to be
#'                passed into the simList (more reliable).
#'                These objects will be accessible
#'                from the simList as a normal list, e.g,. \code{mySim$obj}.
#'
#' @param paths  An optional named list with up to 4 named elements,
#' \code{modulePath}, \code{inputPath}, \code{outputPath}, and \code{cachePath}.
#' See details.
#'
#' @param inputs A \code{data.frame}. Can specify from 1 to 6
#' columns with following column names: \code{objectName} (character, required),
#' \code{file} (character), \code{fun} (character), \code{package} (character),
#' \code{interval} (numeric), \code{loadTime} (numeric).
#' See \code{\link{inputs}} and vignette("ii-modules") section about inputs.
#'
#' @param outputs A \code{data.frame}. Can specify from 1 to 5
#' columns with following column names: \code{objectName} (character, required),
#' \code{file} (character), \code{fun} (character), \code{package} (character),
#' \code{saveTime} (numeric). See \code{\link{outputs}} and
#' \code{vignette("ii-modules")} section about outputs.
#'
#' @param loadOrder  An optional list of module names specifying the order in
#'                   which to load the modules. If not specified, the module
#'                   load order will be determined automatically.
#'
#' @param notOlderThan A time, as in from \code{Sys.time()}. This is passed into
#'                     the \code{Cache} function that wraps \code{.inputObjects}.
#'                     If the module uses the \code{.useCache} parameter and it is
#'                     set to \code{TRUE} or \code{".inputObjects"},
#'                     then the \code{.inputObjects} will be cached.
#'                     Setting \code{notOlderThan = Sys.time()} will cause the
#'                     cached versions of \code{.inputObjects} to be refreshed,
#'                     i.e., rerun.
#'
#' @return A \code{simList} simulation object, pre-initialized from values
#' specified in the arguments supplied.
#'
#' @seealso \code{\link{spades}},
#' \code{\link{times}}, \code{\link{params}}, \code{\link{objs}}, \code{\link{paths}},
#' \code{\link{modules}}, \code{\link{inputs}}, \code{\link{outputs}}
#'
#' @author Alex Chubaty and Eliot McIntire
#' @export
#' @include environment.R
#' @include module-dependencies-class.R
#' @include simList-class.R
#' @include simulation-parseModule.R
#' @include priority.R
#' @importFrom reproducible Require
#' @rdname simInit
#'
#' @references Matloff, N. (2011). The Art of R Programming (ch. 7.8.3).
#'             San Fransisco, CA: No Starch Press, Inc..
#'             Retrieved from \url{https://www.nostarch.com/artofr.htm}
#'
#' @examples
#' \dontrun{
#' mySim <- simInit(
#'  times = list(start = 0.0, end = 2.0, timeunit = "year"),
#'  params = list(
#'    .globals = list(stackName = "landscape", burnStats = "nPixelsBurned")
#'  ),
#'  modules = list("randomLandscapes", "fireSpread", "caribouMovement"),
#'  paths = list(modulePath = system.file("sampleModules", package = "SpaDES.core"))
#' )
#' spades(mySim) # shows plotting
#'
#' # Change more parameters, removing plotting
#' mySim <- simInit(
#'  times = list(start = 0.0, end = 2.0, timeunit = "year"),
#'  params = list(
#'    .globals = list(stackName = "landscape", burnStats = "nPixelsBurned"),
#'    fireSpread = list(.plotInitialTime = NA)
#'  ),
#'  modules = list("randomLandscapes", "fireSpread", "caribouMovement"),
#'  paths = list(modulePath = system.file("sampleModules", package = "SpaDES.core"))
#' )
#' outSim <- spades(mySim)
#'
#' # A little more complicated with inputs and outputs
#' if (require(rgdal)) {
#'  mapPath <- system.file("maps", package = "quickPlot")
#'  mySim <- simInit(
#'    times = list(start = 0.0, end = 2.0, timeunit = "year"),
#'    params = list(
#'      .globals = list(stackName = "landscape", burnStats = "nPixelsBurned")
#'    ),
#'    modules = list("randomLandscapes", "fireSpread", "caribouMovement"),
#'    paths = list(modulePath = system.file("sampleModules", package = "SpaDES.core"),
#'                 outputPath = tempdir()),
#'    inputs = data.frame(
#'      files = dir(file.path(mapPath), full.names = TRUE, pattern = "tif")[1:2],
#'      functions = "raster",
#'      package = "raster",
#'      loadTime = 1,
#'      stringsAsFactors = FALSE),
#'    outputs = data.frame(
#'      expand.grid(objectName = c("caribou","landscape"),
#'      saveTime = 1:2,
#'      stringsAsFactors = FALSE))
#'  )
#'
#'  # Use accessors for inputs, outputs
#'  mySim2 <- simInit(
#'    times = list(current = 0, start = 0.0, end = 2.0, timeunit = "year"),
#'    modules = list("randomLandscapes", "fireSpread", "caribouMovement"),
#'    params = list(.globals = list(stackName = "landscape", burnStats = "nPixelsBurned")),
#'    paths = list(
#'      modulePath = system.file("sampleModules", package = "SpaDES.core"),
#'      outputPath = tempdir()
#'    )
#'  )
#'
#'  # add by accessor is equivalent
#'  inputs(mySim2) <- data.frame(
#'      files = dir(file.path(mapPath), full.names = TRUE, pattern = "tif")[1:2],
#'      functions = "raster",
#'      package = "raster",
#'      loadTime = 1,
#'      stringsAsFactors = FALSE)
#'  outputs(mySim2) <- data.frame(
#'      expand.grid(objectName = c("caribou", "landscape"),
#'      saveTime = 1:2,
#'      stringsAsFactors = FALSE))
#'  all.equal(mySim, mySim2) # TRUE
#'
#'  # Use accessors for times -- does not work as desired because times are
#'  #   adjusted to the input timeunit during simInit
#'  mySim2 <- simInit(
#'    params = list(
#'      .globals = list(stackName = "landscape", burnStats = "nPixelsBurned")
#'    ),
#'    modules = list("randomLandscapes", "fireSpread", "caribouMovement"),
#'    paths = list(modulePath = system.file("sampleModules", package = "SpaDES.core"),
#'                 outputPath = tempdir()),
#'    inputs = data.frame(
#'      files = dir(file.path(mapPath), full.names = TRUE, pattern = "tif")[1:2],
#'      functions = "raster",
#'      package = "raster",
#'      loadTime = 1,
#'      stringsAsFactors = FALSE),
#'    outputs = data.frame(
#'      expand.grid(objectName = c("caribou","landscape"),
#'      saveTime = 1:2,
#'      stringsAsFactors = FALSE))
#'  )
#'
#'  # add times by accessor fails all.equal test because "year" was not
#'  #   declared during module loading, so month became the default
#'  times(mySim2) <- list(current = 0, start = 0.0, end = 2.0, timeunit = "year")
#'  all.equal(mySim, mySim2) # fails because time units are all different, so
#'                           # several parameters that have time units in
#'                           # "months" because they were loaded that way
#'  params(mySim)$fireSpread$.plotInitialTime
#'  params(mySim2)$fireSpread$.plotInitialTime
#'  events(mySim) # load event is at time 1 year
#'  events(mySim2) # load event is at time 1 month, reported in years because of
#'                 #   update to times above
#' }
#' }
#'
setGeneric(
  "simInit",
  function(times, params, modules, objects, paths, inputs, outputs, loadOrder,
           notOlderThan = NULL) {
    standardGeneric("simInit")
})

#' @rdname simInit
setMethod(
  "simInit",
  signature(
    times = "list",
    params = "list",
    modules = "list",
    objects = "list",
    paths = "list",
    inputs = "data.frame",
    outputs = "data.frame",
    loadOrder = "character"
  ),
  definition = function(times,
                        params,
                        modules,
                        objects,
                        paths,
                        inputs,
                        outputs,
                        loadOrder,
                        notOlderThan) {

    # For namespacing of each module; keep a snapshot of the search path
    # .pkgEnv$searchPath <- search()
    # on.exit({
    #   .modifySearchPath(.pkgEnv$searchPath, removeOthers = TRUE)
    # })
    paths <- lapply(paths, checkPath, create = TRUE)

    objNames <- names(objects)
    if (length(objNames) != length(objects)) {
      stop(
        "Please pass a named list or character vector of object names whose values",
        "can be found in the parent frame of the simInit() call"
      )
    }

    # user modules
    modulesLoaded <- list()
    modules <- modules[!sapply(modules, is.null)] %>%
      lapply(., `attributes<-`, list(parsed = FALSE))

    # core modules
    core <- .pkgEnv$.coreModules

    # parameters for core modules
    dotParamsReal <- list(".saveInterval",
                          ".saveInitialTime",
                          ".plotInterval",
                          ".plotInitialTime")
    dotParamsChar <- list(".savePath", ".saveObjects")
    dotParams <- append(dotParamsChar, dotParamsReal)

    # create simList object for the simulation
    sim <- new("simList")

    # Make a temporary place to store parsed module files
    sim@.envir[[".parsedFiles"]] <- new.env(parent = sim@.envir)
    on.exit(rm(".parsedFiles", envir = sim@.envir), add = TRUE )

    paths(sim) <- paths #paths accessor does important stuff
    sim@modules <- modules  ## will be updated below

    reqdPkgs <- packages(modules=unlist(modules), paths = paths(sim)$modulePath,
                         envir = sim@.envir[[".parsedFiles"]])
    if (length(unlist(reqdPkgs))) {
      Require(c(unique(unlist(reqdPkgs), "SpaDES.core")))
    }

    ## timeunit is needed before all parsing of modules.
    ## It could be used within modules within defineParameter statements.
    # timeunits <- .parseModulePartial(sim, modules(sim), defineModuleElement = "timeunit")

    allTimeUnits <- FALSE

    findSmallestTU <- function(sim, mods) {
      out <- lapply(.parseModulePartial(sim, mods,
                                        defineModuleElement = "childModules",
                                        envir = sim@.envir[[".parsedFiles"]]), as.list)
      isParent <- lapply(out, length) > 0
      tu <- .parseModulePartial(sim, mods, defineModuleElement = "timeunit",
                                envir = sim@.envir[[".parsedFiles"]])
      hasTU <- !is.na(tu)
      out[hasTU] <- tu[hasTU]
      if (!all(hasTU)) {
        out[!isParent] <- tu[!isParent]
        while (any(isParent & !hasTU)) {
          for (i in which(isParent & !hasTU)) {
            out[[i]] <- findSmallestTU(sim, as.list(unlist(out[i])))
            isParent[i] <- FALSE
          }
        }
      }
      minTimeunit(as.list(unlist(out)))
    }

    # recursive function to extract parent and child structures
    buildModuleGraph <- function(sim, mods) {
      out <- lapply(.parseModulePartial(sim, modules = mods, defineModuleElement = "childModules",
                                        envir = sim@.envir[[".parsedFiles"]]), as.list)
      isParent <- lapply(out, length) > 0
      to <- unlist(lapply(out, function(x) {
          if (length(x) == 0) {
            names(x)
          } else {
            x
          }
      }))
      if (is.null(to))
        to <- character(0)
      from <- rep(names(out), unlist(lapply(out, length)))
      outDF <- data.frame(from = from, to = to, stringsAsFactors = FALSE)
      while (any(isParent)) {
        for (i in which(isParent)) {
          outDF <- rbind(outDF, buildModuleGraph(sim, as.list(unlist(out[i]))))
          isParent[i] <- FALSE
        }
      }
      outDF
    }

    ## run this only once, at the highest level of the hierarchy, so before the parse tree happens
    moduleGraph <- buildModuleGraph(sim, modules(sim))

    timeunits <- findSmallestTU(sim, modules(sim))

    if (length(timeunits) == 0) timeunits <- list(moduleDefaults$timeunit) # no timeunits or no modules at all

    if (!is.null(times$unit)) {
      message(
        paste0(
          "times contains \'unit\', rather than \'timeunit\'. ",
          "Using \"", times$unit, "\" as timeunit"
        )
      )
      times$timeunit <- times$unit
      times$unit <- NULL
    }

    ## Get correct time unit now that modules are loaded
    timeunit(sim) <- if (!is.null(times$timeunit)) {
      #sim@simtimes[["timeunit"]] <- if (!is.null(times$timeunit)) {
      times$timeunit
    } else {
      minTimeunit(timeunits)
    }

    timestep <- inSeconds(sim@simtimes[["timeunit"]], sim@.envir)
    times(sim) <- list(
      current = times$start * timestep,
      start = times$start * timestep,
      end = times$end * timestep,
      timeunit = sim@simtimes[["timeunit"]]
    )

    ## START OF simInit overrides for inputs, then objects
    if (NROW(inputs)) {
      inputs <- .fillInputRows(inputs, startTime = start(sim))
    }

    ## used to prevent .inputObjects from loading if object is passed in by user.
    sim$.userSuppliedObjNames <- c(objNames, inputs$objectName)

    ## for now, assign only some core & global params
    sim@params$.globals <- params$.globals

    ## add core module name to the loaded list (loaded with the package)
    modulesLoaded <- append(modulesLoaded, core)

    ## source module metadata and code files
    lapply(modules(sim), function(m) moduleVersion(m, sim = sim,
                                                   envir = sim@.envir[[".parsedFiles"]]))

    ## do multi-pass if there are parent modules; first for parents, then for children
    all_parsed <- FALSE
    while (!all_parsed) {
      sim <- .parseModule(sim,
                          sim@modules,
                          userSuppliedObjNames = sim$.userSuppliedObjNames,
                          envir = sim@.envir[[".parsedFiles"]],
                          notOlderThan = notOlderThan, params = params,
                          objects = objects, paths = paths)
      if (length(.unparsed(sim@modules)) == 0) {
        all_parsed <- TRUE
      }
    }

    # Force SpaDES.core to front of search path
    #.modifySearchPath("SpaDES.core", skipNamespacing = FALSE)

    rm(".userSuppliedObjNames", envir=envir(sim))
    ## add name to depends
    if (!is.null(names(sim@depends@dependencies))) {
      names(sim@depends@dependencies) <- sim@depends@dependencies %>%
        lapply(., function(x)
          x@name) %>%
        unlist()
    }

    ## load core modules
    for (c in core) {
      # schedule each module's init event:
      #.refreshEventQueues()
      sim <- scheduleEvent(sim, start(sim, unit = sim@simtimes[["timeunit"]]),
                           c, "init", .normal())
    }

    ## assign user-specified non-global params, while
    ## keeping defaults for params not specified by user
    omit <- c(which(core == "load"), which(core == "save"))
    pnames <-
      unique(c(paste0(".", core[-omit]), names(sim@params)))

    if (is.null(params$.progress) || any(is.na(params$.progress))) {
      params$.progress <- .pkgEnv$.progressEmpty
    }

    tmp <- list()
    lapply(pnames, function(x) {
      tmp[[x]] <<- updateList(sim@params[[x]], params[[x]])
    })
    sim@params <- tmp

    ## check user-supplied load order
    if (!all(length(loadOrder),
             all(sim@modules %in% loadOrder),
             all(loadOrder %in% sim@modules))) {
      loadOrder <- depsGraph(sim, plot = FALSE) %>% .depsLoadOrder(sim, .)
    }

    ## load user-defined modules
    for (m in loadOrder) {
      ## schedule each module's init event:
      sim <- scheduleEvent(sim, sim@simtimes[["start"]], m, "init", .normal())

      ### add module name to the loaded list
      modulesLoaded <- append(modulesLoaded, m)

      ### add NAs to any of the dotParams that are not specified by user
      # ensure the modules sublist exists by creating a tmp value in it
      if (is.null(sim@params[[m]])) {
        sim@params[[m]] <- list(.tmp = NA_real_)
      }

      ## add the necessary values to the sublist
      for (x in dotParamsReal) {
        if (is.null(sim@params[[m]][[x]])) {
          sim@params[[m]][[x]] <- NA_real_
        } else if (is.na(sim@params[[m]][[x]])) {
          sim@params[[m]][[x]] <- NA_real_
        }
      }

      ## remove the tmp value from the module sublist
      sim@params[[m]]$.tmp <- NULL

      ### Currently, everything in dotParamsChar is being checked for NULL
      ### values where used (i.e., in save.R).
    }

    ## check that modules all loaded correctly and store result
    if (all(append(core, loadOrder) %in% modulesLoaded)) {
      modules(sim) <- append(core, loadOrder)
    } else {
      stop("There was a problem loading some modules.")
    }

    ## Add the data.frame as an attribute
    attr(sim@modules, "modulesGraph") <- moduleGraph

    ## END OF MODULE PARSING AND LOADING
    if (length(objects)) {
      if (is.list(objects)) {
        if (length(objNames) == length(objects)) {
          objs(sim) <- objects
        } else {
          stop(
            paste(
              "objects must be a character vector of object names",
              "to retrieve from the .GlobalEnv, or a named list of",
              "objects"
            )
          )
        }
      } else {
        newInputs <- data.frame(
          objectName = objNames,
          loadTime = as.numeric(sim@simtimes[["current"]]),
          stringsAsFactors = FALSE
        ) %>%
          .fillInputRows(startTime = start(sim))
        inputs(sim) <- newInputs
      }
    }

    ## load files in the filelist
    if (NROW(inputs) | NROW(inputs(sim))) {
      inputs(sim) <- rbind(inputs(sim), inputs)
      if (NROW(events(sim)[moduleName == "load" &
                           eventType == "inputs" &
                           eventTime == start(sim)]) > 0) {
        sim <- doEvent.load(sim, sim@simtimes[["current"]], "inputs")
        events(sim) <- events(sim)[!(eventTime == time(sim) &
                                                 moduleName == "load" &
                                                 eventType == "inputs"), ]
      }
      if (any(events(sim)[["eventTime"]] < start(sim))) {
        warning(
          paste0(
            "One or more objects in the inputs filelist was ",
            "scheduled to load before start(sim). ",
            "It is being be removed and not loaded. To ensure loading, loadTime ",
            "must be start(sim) or later. See examples using ",
            "loadTime in ?simInit"
          )
        )
        events(sim) <-
          events(sim)[eventTime >= start(sim)]
      }
    }

    if (length(outputs)) {
      outputs(sim) <- outputs
    }

    ## check the parameters supplied by the user
    checkParams(sim, core, dotParams, sim@paths[["modulePath"]])

    ## keep session info for debugging & checkpointing
    # sim$.sessionInfo <- sessionInfo() # commented out because it gives too much information
                                        # i.e., it includes all packages in a user search
                                        #  path, which is not necessarily the correct info

    return(invisible(sim))
})

## Only deal with objects as character
#' @rdname simInit
setMethod(
  "simInit",
  signature(
    times = "ANY",
    params = "ANY",
    modules = "ANY",
    objects = "character",
    paths = "ANY",
    inputs = "ANY",
    outputs = "ANY",
    loadOrder = "ANY"
  ),
  definition = function(times,
                        params,
                        modules,
                        objects,
                        paths,
                        inputs,
                        outputs,
                        loadOrder,
                        notOlderThan) {
    li <- lapply(names(match.call()[-1]), function(x) eval(parse(text = x)))
    names(li) <- names(match.call())[-1]
    # find the simInit call that was responsible for this, get the objects
    #   in the environment of the parents of that call, and pass them to new
    #   environment.
    li$objects <- .findObjects(objects)
    names(li$objects) <- objects
    sim <- do.call("simInit", args = li)

    return(invisible(sim))
})

## Only deal with modules as character vector
#' @rdname simInit
setMethod(
  "simInit",
  signature(
    times = "ANY",
    params = "ANY",
    modules = "character",
    objects = "ANY",
    paths = "ANY",
    inputs = "ANY",
    outputs = "ANY",
    loadOrder = "ANY"
  ),
  definition = function(times,
                        params,
                        modules,
                        objects,
                        paths,
                        inputs,
                        outputs,
                        loadOrder,
                        notOlderThan) {
    li <- lapply(names(match.call()[-1]), function(x) eval(parse(text = x)))
    names(li) <- names(match.call())[-1]
    li$modules <- as.list(modules)
    sim <- do.call("simInit", args = li)

    return(invisible(sim))
  }
)

###### individual missing elements
#' @rdname simInit
setMethod(
  "simInit",
  signature(
    times = "ANY",
    params = "ANY",
    modules = "ANY",
    objects = "ANY",
    paths = "ANY",
    inputs = "ANY",
    outputs = "ANY",
    loadOrder = "ANY"
  ),
  definition = function(times,
                        params,
                        modules,
                        objects,
                        paths,
                        inputs,
                        outputs,
                        loadOrder,
                        notOlderThan) {
    li <- lapply(names(match.call()[-1]), function(x) eval(parse(text = x)))
    names(li) <- names(match.call())[-1]

    if (missing(times)) li$times <- list(start = 0, end = 10)
    if (missing(params)) li$params <- list()
    if (missing(modules)) li$modules <- list()
    if (missing(objects)) li$objects <- list()
    if (missing(paths)) li$paths <- .paths()
    if (missing(inputs)) li$inputs <- as.data.frame(NULL)
    if (missing(outputs)) li$outputs <- as.data.frame(NULL)
    if (missing(loadOrder)) li$loadOrder <- character(0)

    expectedClasses <- c("list",
                         "list",
                         "list",
                         "list",
                         "list",
                         "data.frame",
                         "data.frame",
                         "character")
    listNames <- names(li)
    expectedOrder <- c("times",
                       "params",
                       "modules",
                       "objects",
                      "paths",
                      "inputs",
                      "outputs",
                      "loadOrder")
    ma <- match(expectedOrder, listNames)
    li <- li[ma]

    if (!all(sapply(1:length(li), function(x) {
      is(li[[x]], expectedClasses[x])
    }))) {
      stop(
        "simInit is incorrectly specified. simInit takes 8 arguments. ",
        "Currently, times, params, modules, and paths must be lists (or missing), ",
        "objects can be named list or character vector (or missing),",
        "inputs and outputs must be data.frames (or missing)",
        "and loadOrder must be a character vector (or missing)",
        "For the currently defined options for simInit, type showMethods('simInit')."
      )
    }
    sim <- do.call("simInit", args = li)

    return(invisible(sim))
})
