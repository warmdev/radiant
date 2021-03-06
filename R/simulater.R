### Make another tab where you can run multiple sims (e.g., grid-search) and
### aggregate the results
### This would also be useful for Conjoint I think

#' Simulate data for decision analysis
#'
#' @details See \url{http://vnijs.github.io/radiant/quant/simulater.html} for an example in Radiant
#'
#' @param const A string listing the constants to include in the analysis (e.g., "cost = 3; size = 4")
#' @param norm A string listing the normally distributed random variables to include in the analysis (e.g., "demand 2000 1000" where the first number is the mean and the second is the standard deviation)
#' @param unif A string listing the uniformly distributed random variables to include in the analysis (e.g., "demand 0 1" where the first number is the minimum value and the second is the maximum value)
#' @param discrete A string listing the random variables with a discrete distribution to include in the analysis (e.g., "price 5 .3 8 .7" where for each pair of numbers the first is the value and the second the probability
#' @param form A string with the formula to evaluate (e.g., "profit = demand * (price - cost)")
#' @param seed To repeat a simulation with the same randomly generated values enter a number into Random seed input box.
#' @param name To save the simulated data for further analysis specify a name in the Sim name input box. You can then investigate the simulated data by choosing the specified name from the Datasets dropdown in any of the other Data tabs.
#' @param nr Number of simulation runs
#' @param dat Data list from previous simulation. Used by repeater function
#'
#' @return A data.frame with the created variables
#'
#' @examples
#' result <- simulater(const = "cost 3", norm = "demand 2000 1000",
#'                     discrete = "price 5 .3 8 .7",
#'                     form = "profit = demand * (price - cost)")
#'
#' @seealso \code{\link{summary.simulater}} to summarize results
#' @seealso \code{\link{plot.simulater}} to plot results
#' @export
simulater <- function(const = "",
                      norm = "",
                      unif = "",
                      discrete = "",
                      form = "",
                      seed = "",
                      name = "",
                      nr = 1000,
                      dat = NULL) {

  # rm(list = ls())
  # const <- "non_labor_cost 3995; cost 11"
  # unif <- "labor_cost 5040 6860"
  # discrete <- "price 20 .25 18.5 .35 16.5 .3 15 .1"
  # norm <- "nr_meals 3000 1000"
  # form <- "profit = (price - cost)*nr_meals - labor_cost - non_labor_cost"
  # seed <- "1234"
  # name <- ""
  # nr <- 1000
  # const = "var_cost 5;fixed_cost 1000"
  # norm = "demand 1000 100"
  # discrete = "price 6 .30 8 .70"
  # form = "profit = demand*(price - var_cost) - fixed_cost"
  # const = "var_cost 5;fixed_cost 1000"
  # norm = "demand 1000 100"
  # discrete = "price 6 .30 8 .70"
  # form = "demand = demand -50*price;profit = demand*(price-var_cost) - fixed_cost"

  # const = "cost 1.25;salvage .5;price 5;q .5:100"
  # norm = "demand 535.74 145"
  # form = "profit = -cost*q + 5*pmin(q,demand) + .5 * pmax(0, q - demand)"
  # seed = "1234"
  # name = "sim1"
  # nr = 1000

  ## remove any non-numbers from seed, including spaces
  seed %>% gsub("[^0-9]","",.) %>% { if(. != "") set.seed(seed) }

  if(is.null(dat)) dat <- list()

  cleaner <- function(x) x %>% gsub("[ ]{2,}"," ",.) %>%
    gsub("[ ]*[\n;]+[ ]*",";",.) %>%
    gsub("[;]{2,}",";",.) %>%
    gsub(";$","",.)

  spliter <- function(x, symbol = " ") x %>% strsplit(., ";") %>% extract2(1) %>% strsplit(.,symbol)

  ## parsing constant
  # const <- "non_labor_cost 3995;\n;\n;cost 11\n   \n \n\n\n\n\n     \n    \n   "
  const %<>% cleaner
  if (const != "") {
    s <- const %>% spliter
    for (i in 1:length(s))
      s[[i]] %>% { dat[[.[1]]] <<- as.numeric(.[2]) %>% rep(,nr) }
  }

  ## parsing uniform
  unif %<>% cleaner
  if (unif != "") {
    s <- unif %>% spliter
    for (i in 1:length(s))
      s[[i]] %>% { dat[[.[1]]] <<- runif(nr, as.numeric(.[2]) , as.numeric(.[3]))}
  }

  ## parsing normal
  norm %<>% cleaner
  if (norm != "") {
    s <- norm %>% spliter
    for (i in 1:length(s))
      s[[i]] %>% { dat[[.[1]]] <<- rnorm(nr, as.numeric(.[2]) , as.numeric(.[3]))}
  }

  ## parsing discrete
  discrete %<>% cleaner
  if (discrete != "") {
    s <- discrete %>% spliter
    for (i in 1:length(s)) {
      par <- s[[i]][-1] %>% as.numeric %>% matrix(nrow = 2)
      if (sum(par[2,]) != 1) message("Probabilities for discrete variable do not sum to 1!")
      dat[[s[[i]][1]]] <- sample(par[1,], nr, replace = TRUE, prob = par[2,])
    }
  }

  ## parsing formula
  # form <- "profit = (price - cost)*nr_meals - labor_cost - non_labor_cost\n ; \n margin = price - cost ;;;   ; \n  \n  "
  # form = "demand = demand -50*price;profit = demand*(price-var_cost) - fixed_cost"
  # form = "demand = demand - .1*lag(demand, 0);profit = demand*(price-var_cost) - fixed_cost"
  # form = "demand = demand - .1*lag(demand, default=0);profit = demand*(price-var_cost) - fixed_cost"
  form %<>% cleaner
  if (form != "") {
    s <- form %>% gsub(" ","",.) %>% spliter("=")
    for (i in 1:length(s)) {
      obj <- s[[i]][1]
      fobj <- s[[i]][-1]
      if(length(fobj) > 1) fobj <- paste0(fobj, collapse = "=")
      out <- try(do.call(with, list(dat, parse(text = fobj))), silent = TRUE)
      if (!is(out, 'try-error')) {
        dat[[obj]] <- out
      } else {
        dat[[obj]] <- NA
        message("Formula", form, "was not successfully evaluated")
      }
    }
  }

  ret <- list(dat = dat %>% as.data.frame, sim_call = as.list(match.call())[-1]) %>%
    set_class(c("simulater", class(.)))

  name %<>% gsub(" ","",.)
  if (name != "") {
    if (exists("r_env")) {
      env <- r_env
    } else if (exists("r_data")) {
      env <- pryr::where("r_data")
    } else {
      return(ret)
    }

    mess <- paste0("\n### Simulated data\n\nFormula: ", form, "\n\nOn: ",
                   lubridate::now())

    env$r_data[[name]] <- ret$dat
    env$r_data[['datasetlist']] <- c(name, env$r_data[['datasetlist']]) %>% unique
    env$r_data[[paste0(name,"_descr")]] <- mess
  }

  ret
}

#' Summary method for the simulater function
#'
#' @details See \url{http://vnijs.github.io/radiant/quant/simulater.html} for an example in Radiant
#'
#' @param object Return value from \code{\link{simulater}}
#' @param ... further arguments passed to or from other methods
#'
#' @examples
#' result <- simulater(norm = "demand 2000 1000")
#' summary(result)
#'
#' @seealso \code{\link{simulater}} to generate the results
#' @seealso \code{\link{plot.simulater}} to plot results
#'
#' @export
summary.simulater <- function(object, ...) {
  getsummary(object$dat)
}

#' Plot method for the simulater function
#'
#' @details See \url{http://vnijs.github.io/radiant/quant/simulater} for an example in Radiant
#'
#' @param x Return value from \code{\link{simulater}}
#' @param shiny Did the function call originate inside a shiny app
#' @param ... further arguments passed to or from other methods
#'
#' @examples
#' result <- simulater(const = "cost 3", norm = "demand 2000 1000",
#'                     discrete = "price 5 .3 8 .7",
#'                     form = "profit = demand * (price - cost)")
#' plot(result)
#'
#' @seealso \code{\link{single_mean}} to generate the result
#' @seealso \code{\link{summary.single_mean}} to summarize results
#'
#' @export
plot.simulater <- function(x, shiny = FALSE, ...) {

  object <- x$dat; rm(x)

  plot_list <- list()
  for (i in colnames(object)) {
    dat <- select_(object, .dots = i)
    if (sd(object[[i]]) == 0) {
      ## plot constants - keep??
      dat$sim <- 1:nrow(dat)
      plot_list[[i]] <- ggplot(dat, aes_string(x = "sim", y = i)) +
        geom_line(color = "blue")
      next
    }

    bw <- diff(range(dat[[1]], na.rm = TRUE)) / 20

    ## plot results
    plot_list[[i]] <-
      ggplot(dat, aes_string(x = i)) +
      geom_histogram(aes(y = ..density..), binwidth = bw, alpha = .3) +
      geom_density(adjust = 1.5, color = "blue")
  }

  sshhr( do.call(arrangeGrob, c(plot_list, list(ncol = min(length(plot_list),2)))) ) %>%
    { if (shiny) . else print(.) }
}

#' Repeat simulation
#'
#' @param nr Number times to repeat the simulation
#' @param vars Variables to use in repeated simulation
#' @param grid Expression to use in grid search for constants
#' @param seed To repeat a simulation with the same randomly generated values enter a number into Random seed input box.
#' @param name To save the simulated data for further analysis specify a name in the Sim name input box. You can then investigate the simulated data by choosing the specified name from the Datasets dropdown in any of the other Data tabs.
#' @param sim Return value from the simulater function
#'
#' @examples
#' result <- simulater(const = "cost 3", norm = "demand 2000 1000",
#'                     discrete = "price 5 .3 8 .7",
#'                     form = "profit = demand * (price - cost)")
#'
#' repeater(sim = result)
#'
#'
#' @export
repeater <- function(nr = 12,
                     vars = "",
                     grid = "",
                     seed = "",
                     name = "",
                     sim = "") {

  # seed <- "1234"
  # nr <- 12
  # sim <- result
  # sim$sim_call
  seed %>% gsub("[^0-9]","",.) %>% { if(. != "") set.seed(seed) }
  if (identical(vars, "")) return()

  ## from http://stackoverflow.com/a/7664655/1974918
  ## keep those list elements that, e.g., q is in
  nr_sim <- nrow(sim$dat)
  sc <- sim$sim_call
  sc$name <- sc$seed <- "" ## cleaning up the sim call
  sc_keep <- grep(paste(vars, collapse = "|"), sc, value=TRUE)
  sc[1:which(names(sc) == "form")] <- ""
  sc[names(sc_keep)] <- sc_keep
  sc$dat <- sim$dat %>% as.list
  sc$form

  rep_sim <- function(run_nr) {
    bind_cols(
      data_frame(run = rep(run_nr, nr_sim), sim = 1:nr_sim),
      do.call(simulater, sc)$dat
    )
  }

  rep_grid_sim <- function(gval) {
    sc_grid <- grep(paste(vars, collapse = "|"), sc_keep, value=TRUE) %>% {.[which(names(.) != "form")]}
    sc[names(sc_grid)] <- sub(paste0("[;\n]", vars, " [.0-9]+"), paste0("\n", vars, " ", gval), sc_grid) %>%
                          sub(paste0("^", vars, " [.0-9]+"), paste0(vars, " ", gval), .)

    bind_cols(
      data_frame(run = rep(gval, nr_sim), sim = 1:nr_sim),
      do.call(simulater, sc)$dat
    )
  }

  if (grid == "") {
    ret <- bind_rows(lapply(1:nr, rep_sim)) %>% set_class(c("repeater", class(.)))
  } else {
    grid %<>% gsub("\"","\'", .) %>% gsub(";",",", .)
    grid <- try(eval(parse(text = paste0("with(sim$dat, expand.grid(", grid ,"))"))), silent = TRUE)
    ret <- bind_rows(lapply(grid[,1], rep_grid_sim)) %>% set_class(c("repeater", class(.)))
  }

  name %<>% gsub(" ","",.)
  if (name != "") {
    if (exists("r_env")) {
      env <- r_env
    } else if (exists("r_data")) {
      env <- pryr::where("r_data")
    } else {
      return(ret)
    }

    mess <- paste0("\n### Data from repeated simulation\n\nFormula: ", sc$form, "\n\nOn: ",
                   lubridate::now())

    env$r_data[[name]] <- ret
    env$r_data[['datasetlist']] <- c(name, env$r_data[['datasetlist']]) %>% unique
    env$r_data[[paste0(name,"_descr")]] <- mess
    return(name %>% set_class(c("repeater", class(.))))
  }

  ret
}

#' Summarize repeated simulation
#'
#' @param object Return value from \code{\link{repeater}}
#' @param sum_vars (Numerical) variables to summaries
#' @param byvar Variable(s) to group data by before summarizing
#' @param fun Functions to use for summarizing
#' @param ... further arguments passed to or from other methods
#'
#' @export
summary.repeater <- function(object,
                             sum_vars = "",
                             byvar = "",
                             fun = c("sum_rm", "mean_rm", "sd_rm"),
                             ...) {
  ## show results
  if (is.character(object)) object <- getdata(object)
  getsummary(object)

  # explore(object, sum_vars, byvar = byvar, fun = fun) %>% summary %>% print
  # object %<>% group_by(sim) %>% summarise(total_profit = sum(profit)) %>%
  #   select(total_profit)

}

#' Plot repeated simulation
#'
#' @param x Return value from \code{\link{repeater}}
#' @param sum_vars (Numerical) variables to summaries
#' @param byvar Variable(s) to group data by before summarizing
#' @param fun Functions to use for summarizing
#' @param shiny Did the function call originate inside a shiny app
#' @param ... further arguments passed to or from other methods
#'
#' @export
plot.repeater <- function(x,
                          sum_vars = "",
                          byvar = "sim",
                          fun = c("sum_rm", "mean_rm", "sd_rm"),
                          shiny = FALSE, ...) {

  object <- x; rm(x)
  if (is.character(object)) object <- getdata(object)
  expl <- explore(object, sum_vars, byvar = byvar, fun = fun)
  plot_list <- list()
  for (l in levels(expl$tab$variable)) {
    for (i in names(expl$pfun)) {

      dat <- expl$tab %>% filter_(paste0("variable == \"", l,"\"")) %>% select_(i)
      bw <- diff(range(dat[[1]], na.rm = TRUE)) / 20

      ## plot results
      plot_list[[paste0(l,"_",i)]] <- ggplot(dat, aes_string(x = i)) +
        geom_histogram(aes(y = ..density..), binwidth = bw, alpha = .3) +
        geom_density(adjust = 1.5, color = "blue") +
        xlab(paste0(i," (",l,")"))
    }
  }

  sshhr( do.call(arrangeGrob, c(plot_list, list(ncol = min(length(plot_list),2)))) ) %>%
    { if (shiny) . else print(.) }
}


# result <- simulater(const = "cost 1.25\nsalvage .5\nprice 5\nq .5", norm = "demand 535.74 145", form = "profit = -cost*q + 5*pmin(q,demand) + .5 * pmax(0, q - demand)", seed = "1234", name = "sim1", nr = 10)
# summary(result)
# plot(result)

# object <- repeater(vars = "q", sim = result, grid = "400:420")
# object %>% print(n = 1020)
# summary(object, sum_vars = c("profit","q"))
# plot(object, sum_vars = c("profit","q"))

# object <- repeater(vars = "q", grid = "500:600", seed = "1234", sim = result)
# class(object)
# summary(object)
# plot(object)

# result <- simulater(const = "non_labor_cost 3995;cost 11", norm = "nr_meals 3000 1000", unif = "labor_cost 5040 6860", discrete = "price 20 .25 18.5 .35 16.5 .3 15 .1", form = "profit = (price - cost)*nr_meals - labor_cost - non_labor_cost", seed = "1234", name = "sim1")
# summary(result)
# plot(result)
# object <- repeater(vars = "nr_meals", sim = result, grid = "")
# viewdata(object)
# summary(object)
# plot(object, sum_vars = "profit")

# library(radiant)
# library(gridExtra)
# result <- simulater(const = "var_cost 5;fixed_cost 1000", norm = "demand 1000 100", discrete = "price 6 .30 8 .70", form = "demand = demand - 50*price;profit = demand*(price-var_cost) - fixed_cost", seed = "1234", name = "sim1")
# summary(result)
# plot(result)

# object <- repeater(vars = "demand", sim = result)
# summary(object, sum_vars = "demand")
# plot(object, sum_vars = "demand")

# nr_meals_sim <- rnorm(nr_sim*12,nr_meals[1],nr_meals[2])
# nr_meals_sim <- matrix(nr_meals_sim, nrow = nr_sim, ncol = 12)

# Es <- (price_sim - cost)*nr_meals_sim - labor_cost_sim - non_labor_cost
# dim(Es)

# Es_annual <- rowSums(Es)

# mean(Es_annual)
# sd(Es_annual)

# Es_annual <- data.frame(Es_annual = Es_annual)
# bw <- diff(range(Es_annual, na.rm = TRUE)) / 20

# # histogram of profits
# ggplot(Es_annual, aes(x=Es_annual)) +
#   geom_histogram(aes(y = ..density..), binwidth = bw, alpha = .3) +
#   geom_density(adjust=1.5, color = "blue", alpha=.3) + labs(y = "") +
#   theme(axis.text.y = element_blank())


# demand <- rnorm(10, 1000,100)
# dyn <- demand + lag(demand, default = 0)
# dyn
