library(testthat)
library(yfR)

options(be_quiet = TRUE)

# Functions for testing output from calls to yf_get
test_yf_output <- function(df_yf, tickers) {

  testthat::expect_true(tibble::is_tibble(df_yf))
  testthat::expect_false(dplyr::is_grouped_df(df_yf))
  testthat::expect_true(nrow(df_yf) > 0)
  testthat::expect_true(dplyr::n_distinct(df_yf$ticker) == length(tickers))

  # check df_control
  df_control <- attributes(df_yf)$df_control
  testthat::expect_true(tibble::is_tibble(df_control))

  return(invisible(TRUE))
}


test_that(desc = "Test of yf_get()", {

  if (!covr::in_covr()) {
    skip_if_offline()
    skip_on_cran() # too heavy for cran
  }

  my_tickers <- c("^GSPC", "^BVSP")

  # vanilla call
  df_yf <- yf_get(
    tickers = my_tickers,
    be_quiet = TRUE
  )

  test_yf_output(df_yf, my_tickers)

  # with cache
  df_yf <- yf_get(
    tickers = my_tickers,
    first_date = Sys.Date() - 60,
    last_date = Sys.Date() - 30,
    do_cache = TRUE,
    be_quiet = TRUE
  )

  # with cache (other folder)
  expect_warning({
    df_yf <- yf_get(
      tickers = my_tickers,
      first_date = Sys.Date() - 60,
      last_date = Sys.Date() - 30,
      do_cache = TRUE,
      cache_folder = file.path("~/other-folder"),
      be_quiet = TRUE
    )})

  test_yf_output(df_yf, my_tickers)

  # with cache (again, for testing caching system and
  # handling of missing portions of data)
  df_yf <- yf_get(
    tickers = my_tickers,
    first_date = Sys.Date() - 90,
    last_date = Sys.Date(),
    do_cache = TRUE,
    be_quiet = TRUE
  )

  test_yf_output(df_yf, my_tickers)

  # no cache
  df_yf <- yf_get(
    tickers = my_tickers,
    first_date = Sys.Date() - 90,
    last_date = Sys.Date(),
    do_cache = FALSE,
    be_quiet = TRUE
  )

  test_yf_output(df_yf, my_tickers)

  # with do_complete_data = TRUE
  df_yf <- yf_get(
    tickers = my_tickers,
    do_complete_data = TRUE,
    be_quiet = TRUE
  )

  test_yf_output(df_yf, my_tickers)

})

test_that(desc = "Test of yf_get(): do_parallel = TRUE", {

  # 20220501 yf now sets api limits, which invalidates any parallel computation
  skip("Skipping since parallel is not supported due to YF api limits")

  if (!covr::in_covr()) {
    skip_if_offline()
    skip_on_cran() # too heavy for cran
  }

  # detect cores and skip if < 2
  n_cores <- 2

  # 20220628 redundant as n_cores is set to 2
  #if (n_cores < 2) {
  #  skip('Not enough cores for parallel computations (< 2)')
  #}

  future::plan(future::multisession,
               workers = n_cores)

  my_tickers <- c("^BVSP", "^GSPC", 'META',
                  "MMM", "GM", "AAPL")

  df_yf <- yf_get(
    tickers = my_tickers,
    first_date = Sys.Date() - 30,
    last_date = Sys.Date(),
    do_parallel = TRUE,
    be_quiet = TRUE
  )

  test_yf_output(df_yf, my_tickers)

})


test_that(desc = "Test of yf_get(): aggregations", {

  if (!covr::in_covr()) {
    skip_if_offline()
    skip_on_cran() # too heavy for cran
  }

  my_tickers <- c("^BVSP", "^GSPC")

  possible_freq <- c('daily', 'weekly', 'monthly', 'yearly')
  possible_agg <- c('first', 'last')

  df_grid <- tidyr::expand_grid(possible_freq,
                                possible_agg)

  for (i_test in seq(1, nrow(df_grid))) {

    tickers <- my_tickers
    first_date <- Sys.Date() - 500
    last_date <- Sys.Date()
    freq_data <- df_grid$possible_freq[i_test]
    how_to_aggregate <- df_grid$possible_agg[i_test]

    df_yf <- yf_get(
      tickers = tickers,
      first_date = first_date,
      last_date = last_date,
      freq_data = freq_data,
      how_to_aggregate = how_to_aggregate,
      be_quiet = TRUE
    )

    test_yf_output(df_yf, my_tickers)
  }

})


test_that(desc = "Test of yf_get(): be_quiet", {

  if (!covr::in_covr()) {
    skip_if_offline()
    skip_on_cran() # too heavy for cran
  }

  my_tickers <- c("^BVSP")

  df_yf <- yf_get(
    tickers = my_tickers,
    be_quiet = TRUE
  )

  test_yf_output(df_yf, my_tickers)

})

test_that(desc = "Test of yf_get(): one trading day", {

  if (!covr::in_covr()) {
    skip_if_offline()
    skip_on_cran() # too heavy for cran
  }

  my_tickers <- c("^GSPC")

  single_day <- as.Date('2022-11-14')

  expect_warning({
    df_yf <- yf_get(
      tickers = my_tickers,
      single_day-1,
      single_day,
      be_quiet = TRUE
    )
  })

})
