#############################################
# View table output of the selected dataset
#############################################
output$ui_view_vars <- renderUI({
  vars <- varnames()
  selectInput("view_vars", "Select variables to show:", choices  = vars,
    selected = state_multiple("view_vars",vars, vars), multiple = TRUE,
    selectize = FALSE, size = min(15, length(vars)))
})

output$ui_View <- renderUI({
  tagList(
    wellPanel(
      uiOutput("ui_view_vars"),
      tags$table(
        tags$td(textInput("view_dat", "Store filtered data as:",
                          state_init("view_dat", paste0(input$dataset,"_view")))),
        tags$td(actionButton("view_store", "Store"), style="padding-top:30px;")
      )
    ),
    help_modal('View','view_help',inclMD(file.path(r_path,"base/tools/help/view.md")))
  )
})

my_dataTablesFilter = function(data, req) {
  ## to implement
}

output$dataviewer <- DT::renderDataTable({

  if (not_available(input$view_vars)) return()
  dat <- select_(.getdata(), .dots = input$view_vars)

  # action = DT::dataTableAjax(session, dat, rownames = FALSE, filter = my_dataTablesFilter)
  DT::datatable(dat, filter = list(position = "top", clear = FALSE, plain = TRUE),
    rownames = FALSE, style = "bootstrap", escape = FALSE,
    options = list(
      # stateSave = TRUE,   ## maintains state but does not show column filter settings
      # search = list(regex = TRUE, search = "G", order = list(list(2, 'asc'), list(1, 'desc'))),
      search = list(regex = TRUE),
      autoWidth = TRUE,
      columnDefs = list(list(className = 'dt-center', targets = "_all")),
      processing = FALSE,
      pageLength = 10,
      lengthMenu = list(c(10, 25, 50, -1), c('10','25','50','All'))
    )
  )
})

observeEvent(input$view_store, {
  isolate({
    view_store(input$dataset, input$view_vars, input$view_dat, input$data_filter, input$dataviewer_rows_all)
    updateTextInput(session, "data_filter", value = "")
    updateCheckboxInput(session = session, inputId = "show_filter", value = FALSE)

  })
})

view_store <- function(dataset,
                       vars = "",
                       view_dat = dataset,
                       data_filter = "",
                       rows = NULL) {

  mess <-
    if (data_filter != "" && !is.null(rows))
      paste0("\nSaved filtered data: ", data_filter, " and view-filter (", lubridate::now(), ")")
    else if (is.null(rows))
      paste0("\nSaved filtered data: ", data_filter, " (", lubridate::now(), ")")
    else if (data_filter == "")
      paste0("\nSaved data with view-filter (", lubridate::now(), ")")
    else
      ""

  getdata(dataset, vars = vars, filt = data_filter, rows = rows, na.rm = FALSE) %>%
    save2env(dataset, view_dat, mess)
}

output$dl_view_tab <- downloadHandler(
  filename = function() { paste0("view_tab.csv") },
  content = function(file) {
    getdata(input$dataset, vars = input$view_vars, filt = input$data_filter,
            rows = input$dataviewer_rows_all, na.rm = FALSE) %>%
      write.csv(file, row.names = FALSE)
  }
)

## cannot (re)set state ... yet
# search = list(search = 'Ma'), order = list(list(2, 'asc'), list(1, 'desc'))
# output$tbl_state <- renderPrint(str(input$dataviewer_state))
