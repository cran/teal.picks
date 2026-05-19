## ----setup, include = FALSE---------------------------------------------------
knitr::opts_chunk$set(comment = NA)

## ----data, message = FALSE----------------------------------------------------
library(teal)
library(teal.data)
library(teal.picks)

data <- teal_data()
data <- within(data, {
  ADSL <- teal.data::rADSL
  ADLB <- teal.data::rADLB
})

join_keys(data) <- teal.data::default_cdisc_join_keys[c("ADSL", "ADLB")]

## ----picks-datasets-----------------------------------------------------------
picks_datasets <- list(
  source = picks(
    datasets(
      choices = c("ADSL", "ADLB"),
      selected = "ADLB"
    )
  )
)

## ----picks-datasets-variables-------------------------------------------------
picks_datasets_variables <- list(
  adsl_cols = picks(
    datasets(choices = "ADSL", selected = "ADSL"),
    variables(
      choices = c("USUBJID", "AGE", "SEX"),
      selected = "AGE",
      multiple = FALSE
    )
  )
)

## ----picks-datasets-variables-values------------------------------------------
picks_datasets_variables_values <- list(
  labs = picks(
    datasets(choices = "ADLB", selected = "ADLB"),
    variables(choices = "PARAM", selected = "PARAM", multiple = FALSE),
    values(
      choices = c("ALT", "AST", "CRP", "GLU"),
      selected = c("ALT", "AST"),
      multiple = TRUE
    )
  )
)

## ----defaults-----------------------------------------------------------------
picks(
  datasets(choices = "ADSL", selected = "ADSL"),
  variables()
)

picks(
  datasets(choices = "ADSL", selected = "ADSL"),
  variables(choices = "SEX", selected = "SEX", multiple = FALSE),
  values()
)

## ----static-------------------------------------------------------------------
# Datasets — user may switch between ADSL and ADLB; ADSL is the default
p_datasets <- picks(
  datasets(
    choices  = c("ADSL", "ADLB"),
    selected = "ADSL"
  )
)

# Variables — only a named subset is offered; first column pre-selected
p_variables <- picks(
  datasets(choices = "ADSL", selected = "ADSL"),
  variables(
    choices  = c("AGE", "SEX", "ARM"),
    selected = "AGE",
    multiple = FALSE
  )
)

# Values — categorical filter; two levels pre-selected
p_values <- picks(
  datasets(choices = "ADSL", selected = "ADSL"),
  variables(choices = "SEX", selected = "SEX", multiple = FALSE),
  values(
    choices  = c("M", "F"),
    selected = "F"
  )
)

p_datasets
p_variables
p_values

## ----tidyselect---------------------------------------------------------------
# Datasets — offer any data.frame in the teal_data object
p_any_dataset <- picks(
  datasets(
    choices  = tidyselect::where(is.data.frame),
    selected = 1L # first dataset by default
  )
)

# Variables — all numeric columns; first one pre-selected
p_numeric_vars <- picks(
  datasets(choices = "ADSL", selected = "ADSL"),
  variables(
    choices  = tidyselect::where(is.numeric),
    selected = 1L,
    multiple = FALSE
  )
)

# Variables — columns whose names start with "A"; first two pre-selected
p_a_prefix <- picks(
  datasets(choices = "ADSL", selected = "ADSL"),
  variables(
    choices  = tidyselect::starts_with("A"),
    selected = 1L:2L,
    multiple = TRUE
  )
)

p_any_dataset
p_numeric_vars
p_a_prefix

## ----functions----------------------------------------------------------------
# Variables — use the package helper is_categorical() as a column predicate.
# Without "des-delayed", the resolver calls it via vapply(data, fn, logical(1)),
# so it must accept one column and return a single logical value — which is_categorical() does.
picks(
  datasets(choices = "ADSL", selected = "ADSL"),
  variables(
    choices  = is_categorical(),
    selected = 1L,
    multiple = TRUE
  )
)

# Values — select only even ages from the AGE column.
# Functions passed to values() must carry the "des-delayed" class so the resolver
# calls them with the column vector rather than treating them as a column predicate.
even_vals <- function(x) sort(unique(x[x %% 2 == 0]))
class(even_vals) <- append(class(even_vals), "des-delayed")

p_even_ages <- picks(
  datasets(choices = "ADSL", selected = "ADSL"),
  variables(choices = "AGE", selected = "AGE", multiple = FALSE),
  values(
    choices  = even_vals,
    selected = even_vals
  )
)

p_even_ages

## ----picks-multiple-variables-------------------------------------------------
picks_multiple_variables <- list(
  demo = picks(
    datasets(choices = "ADSL", selected = "ADSL"),
    variables(
      choices = c("USUBJID", "AGE", "SEX"),
      selected = c("AGE", "SEX"),
      multiple = TRUE,
      ordered = TRUE
    )
  )
)

## ----teal-app, eval = FALSE---------------------------------------------------
# library(shiny)
# 
# app <- init(
#   data = data,
#   modules = modules(
#     modules(
#       label = "teal.picks patterns",
#       tm_merge(
#         label = "1. Dataset choice",
#         picks = picks_datasets
#       ),
#       tm_merge(
#         label = "2. Dataset & variables",
#         picks = picks_datasets_variables
#       ),
#       tm_merge(
#         label = "3. Dataset, variables & values",
#         picks = picks_datasets_variables_values
#       ),
#       tm_merge(
#         label = "4. Multiple variables",
#         picks = picks_multiple_variables
#       )
#     )
#   )
# )
# 
# if (interactive()) {
#   shinyApp(app$ui, app$server)
# }

## ----module-skeleton, eval = FALSE--------------------------------------------
# tm_picks_preview <- function(label = "Custom picks module", picks) {
#   teal::module(
#     label = label,
#     ui = function(id, picks) {
#       ns <- shiny::NS(id)
#       shiny::tagList(
#         teal.picks::picks_ui(ns("sel"), picks = picks),
#         shiny::tags$h5("Preview (first rows)"),
#         shiny::tableOutput(ns("preview")),
#         shiny::tags$h5("Resolved picks"),
#         shiny::verbatimTextOutput(ns("resolved"))
#       )
#     },
#     server = function(id, data, picks) {
#       shiny::moduleServer(id, function(input, output, session) {
#         resolved <- teal.picks::picks_srv("sel", picks = picks, data = data)
#         preview_tbl <- shiny::reactive({
#           shiny::req(data(), resolved())
#           ds <- resolved()$datasets$selected
#           vars <- resolved()$variables$selected
#           shiny::req(length(ds) == 1L, length(vars) >= 1L)
#           data()[[ds]][, vars, drop = FALSE]
#         })
#         output$preview <- shiny::renderTable({
#           utils::head(preview_tbl(), 8L)
#         })
#         output$resolved <- shiny::renderPrint({
#           shiny::req(resolved())
#           str(resolved(), max.level = 2L, give.attr = FALSE)
#         })
#       })
#     },
#     ui_args = list(picks = picks),
#     server_args = list(picks = picks),
#     datanames = "ADSL"
#   )
# }
# 
# app <- init(
#   data = data,
#   modules = modules(
#     tm_picks_preview(
#       label = "Custom picks module",
#       picks = picks_datasets_variables$adsl_cols
#     )
#   )
# )
# 
# if (interactive()) {
#   shinyApp(app$ui, app$server)
# }

