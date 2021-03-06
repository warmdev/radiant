################################################################
# Regression - UI
################################################################
reg_show_interactions <- c("None" = "", "2-way" = 2, "3-way" = 3)
reg_predict <- c("None" = "", "Data" = "data","Command" = "cmd")
reg_check <- c("Standardized coefficients" = "standardize",
               "Stepwise selection" = "stepwise")
reg_sum_check <- c("RMSE" = "rmse", "Sum of squares" = "sumsquares",
                   "VIF" = "vif", "Confidence intervals" = "confint")
reg_lines <- c("Line" = "line", "Loess" = "loess")
reg_plots <- c("None" = "", "Histograms" = "hist",
               "Correlations" = "correlations", "Scatter" = "scatter",
               "Dashboard" = "dashboard",
               "Residual vs predictor" = "resid_pred",
               "Coefficient plot" = "coef",
               "Leverage plots" = "leverage")

reg_args <- as.list(formals(regression))

## list of function inputs selected by user
reg_inputs <- reactive({
  ## loop needed because reactive values don't allow single bracket indexing
  reg_args$data_filter <- if (input$show_filter) input$data_filter else ""
  reg_args$dataset <- input$dataset
  for (i in r_drop(names(reg_args)))
    reg_args[[i]] <- input[[paste0("reg_",i)]]
  reg_args
})

reg_sum_args <- as.list(if (exists("summary.regression")) formals(summary.regression)
                        else formals(radiant:::summary.regression))

## list of function inputs selected by user
reg_sum_inputs <- reactive({
  ## loop needed because reactive values don't allow single bracket indexing
  for (i in names(reg_sum_args))
    reg_sum_args[[i]] <- input[[paste0("reg_",i)]]
  reg_sum_args
})

reg_plot_args <- as.list(if (exists("plot.regression")) formals(plot.regression)
                         else formals(radiant:::plot.regression))

## list of function inputs selected by user
reg_plot_inputs <- reactive({
  ## loop needed because reactive values don't allow single bracket indexing
  for (i in names(reg_plot_args))
    reg_plot_args[[i]] <- input[[paste0("reg_",i)]]
  reg_plot_args
})

reg_pred_args <- as.list(if (exists("predict.regression")) formals(predict.regression)
                         else formals(radiant:::predict.regression))

## list of function inputs selected by user
reg_pred_inputs <- reactive({
  ## loop needed because reactive values don't allow single bracket indexing
  for (i in names(reg_pred_args))
    reg_pred_args[[i]] <- input[[paste0("glm_",i)]]

  reg_pred_args$pred_cmd <- reg_pred_args$pred_data <- ""
  if (input$reg_predict == "cmd")
    reg_pred_args$pred_cmd <- gsub("\\s", "", input$reg_pred_cmd)

  if (input$reg_predict == "data")
    reg_pred_args$pred_data <- input$reg_pred_data

  reg_pred_args
})

reg_pred_plot_args <- as.list(if (exists("plot.reg_predict")) formals(plot.reg_predict)
                         else formals(radiant:::plot.reg_predict))

## list of function inputs selected by user
reg_pred_plot_inputs <- reactive({
  ## loop needed because reactive values don't allow single bracket indexing
  for (i in names(reg_pred_plot_args))
    reg_pred_plot_args[[i]] <- input[[paste0("reg_",i)]]
  reg_pred_plot_args
})

output$ui_reg_dep_var <- renderUI({
	isNum <- "numeric" == .getclass() | "integer" == .getclass()
 	vars <- varnames()[isNum]
  selectInput(inputId = "reg_dep_var", label = "Dependent variable:", choices = vars,
  	selected = state_single("reg_dep_var",vars), multiple = FALSE)
})

output$ui_reg_indep_var <- renderUI({
	notChar <- "character" != .getclass()
  vars <- varnames()[notChar]
  if (not_available(input$reg_dep_var)) vars <- character(0)
  if (length(vars) > 0 ) vars <- vars[-which(vars == input$reg_dep_var)]

  ## if possible, keep current indep value when depvar changes
  isolate({
    init <-
      input$reg_indep_var %>%
      {if(!is_empty(.) && . %in% vars) . else character(0)}
  })

  selectInput(inputId = "reg_indep_var", label = "Independent variables:", choices = vars,
  	selected = state_multiple("reg_indep_var", vars, init),
  	multiple = TRUE, size = min(10, length(vars)), selectize = FALSE)
})

# adding interaction terms as needed
output$ui_reg_test_var <- renderUI({
  vars <- input$reg_indep_var
  if (!is.null(input$reg_int_var)) vars <- c(vars, input$reg_int_var)

  selectizeInput(inputId = "reg_test_var", label = "Variables to test:",
    choices = vars, selected = state_multiple("reg_test_var", vars, ""),
    multiple = TRUE,
    options = list(placeholder = 'None', plugins = list('remove_button'))
  )
})

output$ui_reg_show_interactions <- renderUI({
  if (length(input$reg_indep_var) == 2)
    choices <- reg_show_interactions[1:2]
  else if (length(input$reg_indep_var) > 2)
    choices <- reg_show_interactions
  else
    choices <- reg_show_interactions[1]

  radioButtons(inputId = "reg_show_interactions", label = "Interactions:",
               choices = choices,
               selected = state_init("reg_show_interactions"), inline = TRUE)
 })

output$ui_reg_int_var <- renderUI({
  if (is_empty(input$reg_show_interactions)) {
    choices <- character(0)
  } else {
    vars <- input$reg_indep_var
    if (not_available(vars) || length(vars) < 2) return()
    # vector of possible interaction terms to sel from glm_reg
    choices <- iterms(vars, input$reg_show_interactions)       # create list of interactions to show user
  }
	selectInput("reg_int_var", label = NULL, choices = choices,
  	selected = state_multiple("reg_int_var", choices),
  	multiple = TRUE, size = min(4,length(choices)), selectize = FALSE)
})

# X - variable
output$ui_reg_xvar <- renderUI({
  vars <- input$reg_indep_var
  selectizeInput(inputId = "reg_xvar", label = "X-variable:", choices = vars,
    selected = state_multiple("reg_xvar",vars),
    multiple = FALSE)
})

output$ui_reg_facet_row <- renderUI({
  vars <- input$reg_indep_var
  vars <- c("None" = ".", vars)
  selectizeInput("reg_facet_row", "Facet row", vars,
                 selected = state_single("reg_facet_row", vars, "."),
                 multiple = FALSE)
})

output$ui_reg_facet_col <- renderUI({
  vars <- input$reg_indep_var
  vars <- c("None" = ".", vars)
  selectizeInput("reg_facet_col", 'Facet column', vars,
                 selected = state_single("reg_facet_col", vars, "."),
                 multiple = FALSE)
})

output$ui_reg_color <- renderUI({
  vars <- c("None" = "none", input$reg_indep_var)
  sel <- state_single("reg_color", vars, "none")
  selectizeInput("reg_color", "Color", vars, selected = sel,
                 multiple = FALSE)
})

output$ui_regression <- renderUI({
  tagList(
    conditionalPanel(condition = "input.tabs_regression == 'Predict'",
      wellPanel(
        radioButtons(inputId = "reg_predict", label = "Prediction:", reg_predict,
          selected = state_init("reg_predict", ""), inline = TRUE),
        conditionalPanel(condition = "input.reg_predict == 'cmd'",
          returnTextAreaInput("reg_pred_cmd", "Prediction command:",
            value = state_init("reg_pred_cmd", ""))
        ),
        conditionalPanel(condition = "input.reg_predict == 'data'",
          selectizeInput(inputId = "reg_pred_data", label = "Predict for profiles:",
                      choices = c("None" = "",r_data$datasetlist),
                      selected = state_init("reg_pred_data", ""), multiple = FALSE)
        ),
        conditionalPanel(condition = "input.reg_predict != ''",
          uiOutput("ui_reg_xvar"),
          uiOutput("ui_reg_facet_row"),
          uiOutput("ui_reg_facet_col"),
          uiOutput("ui_reg_color"),
          downloadButton("reg_save_pred", "Predictions")
        )
      )
    ),
	  conditionalPanel(condition = "input.tabs_regression == 'Plot'",
      wellPanel(
  	    selectInput("reg_plots", "Regression plots:", choices = reg_plots,
  		  	selected = state_single("reg_plots", reg_plots)),
        conditionalPanel(condition = "input.reg_plots == 'coef'",
        	checkboxInput("reg_intercept", "Include intercept", state_init("reg_intercept", FALSE))
        ),
        conditionalPanel(condition = "input.reg_plots == 'scatter' |
                                      input.reg_plots == 'dashboard' |
                                      input.reg_plots == 'resid_pred'",
          checkboxGroupInput("reg_lines", NULL, reg_lines,
            selected = state_init("reg_lines"), inline = TRUE)
        )
      )
	  ),
    wellPanel(
	    uiOutput("ui_reg_dep_var"),
	    uiOutput("ui_reg_indep_var"),

      conditionalPanel(condition = "input.reg_indep_var != null",

  			uiOutput("ui_reg_show_interactions"),
        conditionalPanel(condition = "input.reg_show_interactions != ''",
  				uiOutput("ui_reg_int_var")
  			),
  		  conditionalPanel(condition = "input.tabs_regression == 'Summary'",
  		    uiOutput("ui_reg_test_var"),
          checkboxGroupInput("reg_check", NULL, reg_check,
            selected = state_init("reg_check"), inline = TRUE),
          checkboxGroupInput("reg_sum_check", NULL, reg_sum_check,
            selected = state_init("reg_sum_check"), inline = TRUE)
  			),
        conditionalPanel(condition = "input.reg_predict == 'cmd' |
                         input.reg_predict == 'data' |
  	                     (input.reg_sum_check && input.reg_sum_check.indexOf('confint') >= 0) |
  	                     input.reg_plots == 'coef'",
   					 sliderInput("reg_conf_lev", "Adjust confidence level:", min = 0.70,
   					             max = 0.99, value = state_init("reg_conf_lev",.95),
   					             step = 0.01)
  		  ),
        conditionalPanel(condition = "input.tabs_regression == 'Summary'",
          actionButton("reg_store_res", "Store residuals")
        )
      )
	  ),
  	help_and_report(modal_title = "Linear regression (OLS)",
  	                fun_name = "regression",
  	                help_file = inclRmd(file.path(r_path,"quant/tools/help/regression.Rmd")))
	)
})


reg_plot <- reactive({

  if (reg_available() != "available") return()
  if (is_empty(input$reg_plots)) return()

  # specifying plot heights
  plot_height <- 500
  plot_width <- 650
  nrVars <- length(input$reg_indep_var) + 1

  if (input$reg_plots == 'hist') plot_height <- (plot_height / 2) * ceiling(nrVars / 2)
  if (input$reg_plots == 'dashboard') plot_height <- 1.5 * plot_height
  if (input$reg_plots == 'correlations') { plot_height <- 150 * nrVars; plot_width <- 150 * nrVars }
  if (input$reg_plots == 'coef') plot_height <- 300 + 20 * length(.regression()$model$coefficients)
  if (input$reg_plots %in% c('scatter','leverage','resid_pred'))
    plot_height <- (plot_height/2) * ceiling((nrVars-1) / 2)

  list(plot_width = plot_width, plot_height = plot_height)
})

reg_plot_width <- function()
  reg_plot() %>% { if (is.list(.)) .$plot_width else 650 }

reg_plot_height <- function()
  reg_plot() %>% { if (is.list(.)) .$plot_height else 500 }

reg_pred_plot_height <- function()
  if (input$tabs_regression == "Predict" && is.null(r_data$reg_pred)) 0 else 500

# output is called from the main radiant ui.R
output$regression <- renderUI({

		register_print_output("summary_regression", ".summary_regression")
    register_print_output("predict_regression", ".predict_regression")
    register_plot_output("predict_plot_regression", ".predict_plot_regression",
                          height_fun = "reg_pred_plot_height")
		register_plot_output("plot_regression", ".plot_regression",
                         height_fun = "reg_plot_height",
                         width_fun = "reg_plot_width")

		# two separate tabs
		reg_output_panels <- tabsetPanel(
	    id = "tabs_regression",
	    tabPanel("Summary", verbatimTextOutput("summary_regression")),
      tabPanel("Predict",
               plot_downloader("regression", height = reg_pred_plot_height(), po = "dlp_", pre = ".predict_plot_"),
               plotOutput("predict_plot_regression", width = "100%", height = "100%"),
               verbatimTextOutput("predict_regression")),
	    tabPanel("Plot", plot_downloader("regression", height = reg_plot_height()),
               plotOutput("plot_regression", width = "100%", height = "100%"))
	  )

		stat_tab_panel(menu = "Regression",
		              tool = "Linear (OLS)",
		              tool_ui = "ui_regression",
		             	output_panels = reg_output_panels)
})

reg_available <- reactive({

  if (not_available(input$reg_dep_var))
    return("This analysis requires a dependent variable of type integer\nor numeric and one or more independent variables.\nIf these variables are not available please select another dataset.\n\n" %>% suggest_data("diamonds"))

  if (not_available(input$reg_indep_var))
    return("Please select one or more independent variables.\n\n" %>% suggest_data("diamonds"))

  "available"
})

.regression <- reactive({
	do.call(regression, reg_inputs())
})

.summary_regression <- reactive({
  if (reg_available() != "available") return(reg_available())
  if (input$reg_dep_var %in% input$reg_indep_var) return()
  do.call(summary, c(list(object = .regression()), reg_sum_inputs()))
})

.predict_regression <- reactive({
  r_data$reg_pred <- NULL
  if (reg_available() != "available") return(reg_available())
  if (is_empty(input$reg_predict)) return(invisible())
  r_data$reg_pred <- do.call(predict, c(list(object = .regression()), reg_pred_inputs()))
})

.predict_plot_regression <- reactive({
  if (is_empty(input$reg_predict) || is.null(r_data$reg_pred))
    return(invisible())
  do.call(plot, c(list(x = r_data$reg_pred), reg_pred_plot_inputs()))
})

.plot_regression <- reactive({

  if (reg_available() != "available") return(reg_available())
  if (is_empty(input$reg_plots))
    return("Please select a regression plot from the drop-down menu")

  if (input$reg_plots %in% c("correlations", "leverage"))
    capture_plot( do.call(plot, c(list(x = .regression()), reg_plot_inputs())) )
  else
    reg_plot_inputs() %>% { .$shiny <- TRUE; . } %>% { do.call(plot, c(list(x = .regression()), .)) }
})

observeEvent(input$regression_report, {
  isolate({
    outputs <- c("summary","# store_reg_resid")
    inp_out <- list("","")
    inp_out[[1]] <- clean_args(reg_sum_inputs(), reg_sum_args[-1])
    figs <- FALSE
    if (!is_empty(input$reg_plots)) {
      inp_out[[3]] <- clean_args(reg_plot_inputs(), reg_plot_args[-1])
      outputs <- c(outputs, "plot")
      figs <- TRUE
    }
    xcmd <- ""
    if (!is.null(r_data$reg_pred)) {
      inp_out[[3 + figs]] <- clean_args(reg_pred_inputs(), reg_pred_args[-1])
      outputs <- c(outputs, "result <- predict")
      xcmd <- paste0("# write.csv(result, file = '~/reg_sav_pred.csv', row.names = FALSE)")
      if (!is_empty(input$reg_xvar)) {
        inp_out[[4 + figs]] <- clean_args(reg_pred_plot_inputs(), reg_pred_plot_args[-1])
        outputs <- c(outputs, "plot")
        figs <- TRUE
      }
    }
    update_report(inp_main = clean_args(reg_inputs(), reg_args),
                  fun_name = "regression", inp_out = inp_out,
                  outputs = outputs, figs = figs,
                  fig.width = round(7 * reg_plot_width()/650,2),
                  fig.height = round(7 * reg_plot_height()/650,2),
                  xcmd = xcmd)
  })
})

observeEvent(input$reg_store_res, {
	isolate({
    .regression() %>% { if (is.list(.)) store_reg_resid(.) }
	})
})

output$reg_save_pred <- downloadHandler(
  filename = function() { "reg_save_pred.csv" },
  content = function(file) {
    do.call(predict, c(list(object = .regression()), reg_pred_inputs(),
            list(reg_save_pred = TRUE))) %>%
      write.csv(., file = file, row.names = FALSE)
  }
)
