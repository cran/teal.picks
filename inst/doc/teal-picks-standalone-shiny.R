## ----setup, include = FALSE---------------------------------------------------
knitr::opts_chunk$set(comment = NA)

## ----data, message = FALSE----------------------------------------------------
library(shiny)
library(teal.data)
library(teal.picks)

data <- teal_data()
data <- within(data, {
  ADSL <- data.frame(
    USUBJID = sprintf("S%03d", 1:8),
    AGE = sample(35:70, 8, replace = TRUE),
    stringsAsFactors = FALSE
  )
  ADLB <- data.frame(
    USUBJID = rep(sprintf("S%03d", 1:8), each = 3),
    PARAM = rep(c("ALT", "AST", "BILI"), 8),
    AVAL = round(rnorm(24, 42, 6), 1),
    stringsAsFactors = FALSE
  )
})

join_keys(data) <- join_keys(teal.data::join_key("ADSL", "ADLB", keys = "USUBJID"))

selector_default <- picks(
  datasets(choices = c("ADSL", "ADLB"), selected = "ADLB"),
  variables(
    choices = tidyselect::everything(),
    selected = c(1L, 2L),
    multiple = TRUE
  )
)

## ----standalone-app, eval = FALSE---------------------------------------------
# ui <- fluidPage(
#   titlePanel("Standalone picks + merge"),
#   fluidRow(
#     column(
#       width = 4,
#       picks_ui("sel", picks = selector_default)
#     ),
#     column(
#       width = 8,
#       tags$h4("Mapped variables"),
#       verbatimTextOutput("mapped"),
#       tags$h4("Merge preview"),
#       tableOutput("merged")
#     )
#   )
# )
# 
# server <- function(input, output, session) {
#   data_r <- reactive(data)
# 
#   selectors <- list(sel = picks_srv("sel", picks = selector_default, data = data_r))
# 
#   merged <- merge_srv(
#     id = "merge",
#     data = data_r,
#     selectors = selectors,
#     output_name = "anl",
#     join_fun = "dplyr::left_join"
#   )
# 
#   output$mapped <- renderPrint({
#     yaml::as.yaml(merged$variables())
#   })
# 
#   output$merged <- renderTable({
#     merged$data()[["anl"]]
#   })
# }
# 
# if (interactive()) {
#   shinyApp(ui, server)
# }

