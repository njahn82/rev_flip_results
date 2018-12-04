# analyzing journals in the master list
library(tidyverse)
library(googledrive)
library(rcrossref)
googledrive::drive_download(as_id("1aCYAUoQ0xYEQeBAP8GixuTkq-UyPZD3fBMPPsQxjmUc"), "master_list.xlsx", overwrite = TRUE)
my_df <- readxl::read_xlsx("master_list.xlsx", sheet= 3) 
issn_tmp <- readr::read_csv("data/issn_validate.csv") %>%
  filter(!is.na(new))
my_df %>%
  mutate(issn = ifelse(issn %in% issn_tmp$old, issn_tmp$new, issn))
# get all issn variants in first place
jn_facets <- purrr::map(my_df$issn, .f = purrr::safely(function(x) {
  tt <- rcrossref::cr_works(
    filter = c(
      issn = x,
      from_pub_date = "2004-01-01",
      until_pub_date = "2018-12-31",
      type = "journal-article"
    ),
    facet = TRUE,
    # less api traffic
    select = "DOI"
  )
  #' Parse the relevant information
  #' - `issn` - issns  found in open apc data set
  #' - `year_published` - published volume per year (Earliest year of publication)
  #' - `license_refs` - facet counts for license URIs of work
  #' - `journal_title` - Crossref journal title (in case of journal name change, we use the most frequent name)
  #' - `publisher` - Crossref publisher (in case of publisher name change, we use the most frequent name)
  #'
  #' To Do: switch to current potential
  if (!is.null(tt)) {
    tibble::tibble(
      issn = x,
      year_published = list(tt$facets$published),
      cr_issn = list(tt$facets$issn),
      license_refs = list(tt$facets$license),
      journal_title = tt$facets$`container-title`$.id[1],
      publisher = tt$facets$publisher$.id[1]
    )
  } else {
    NULL
  }
}))
purrr::map_df(jn_facets, "result") %>% 
  unnest(cr_issn) %>% 
  mutate(issn_cr = gsub("http://id.crossref.org/issn/", "", .id)) %>%
  distinct(issn, journal_title, issn_cr) -> issn_mapping
write_csv(issn_mapping, "issn_matching_cr.csv")
#' redo crossref fetch with all ISSN variants because journal publication volume may vary by issn 
issn_mapping <- readr::read_csv("issn_matching_cr.csv")
#' add missing issns from (Chinese Science Bulletin) and other journals where no data for 2018 was available.
#' in many cases this was due to journal issn and publisher change. Here are the ones found:
changed_jns <- tribble(~issn, ~journal_title, ~issn_cr,
               "1861-9541", "Chinese Science Bulletin", "2095-9273",
               "1861-9541", "Chinese Science Bulletin", "2095-9281",
               "1566-5399", "Ars Disputandi", "2169-2335",
               "0253-2964", "Bulletin of the Korean Chemical Society", "1229-5949",
               "1546-3222", "Proceedings of the American Thoracic Society", "2325-6621",
               "1546-3222", "Proceedings of the American Thoracic Society", "2329-6933",
               "1982-5676", "Tropical Plant Pathology", "1983-2052",
               "1672-1977", "Journal of Chinese Integrative Medicine", "2095-4964",
               "0035-8835", "Journal of the Royal College of Surgeons of Edinburgh", "1479-666X",
               "2351-9797", "Advances in Digestive Medicine", "2351-9800")
issn_mapping <- bind_rows(issn_mapping, changed_jns)
issns_list <-
  purrr::map(unique(issn_mapping$journal_title), function(x) {
    issns <- issn_mapping %>%
      filter(journal_title == x) %>%
      .$issn_cr
    names(issns) <- rep("issn", length(issns))
    as.list(issns)
  })
jn_md <- purrr::map(issns_list, .f = purrr::safely(function(x) {
  issn = x
  rcrossref::cr_works(
    filter = c(
      issn,
      from_pub_date = "2000-01-01",
      until_pub_date = "2018-12-31",
      type = "journal-article"),
      cursor = "*", 
      cursor_max = 50000L, 
      limit = 1000L)$data %>%
    as_data_frame()}))
jn_md_df <- purrr::map_df(jn_md, "result", .id = "id") %>%
  select_if(is.character) %>%
  select(-abstract)
issn_mapping %>%
  distinct(journal_title, issn) %>% 
  mutate(id = rownames(.)) %>%
  inner_join(jn_md_df, by = "id") %>%
  readr::write_csv("data/cr_md.csv")




  #' Parse the relevant information
  #' - `issn` - issns  found in open apc data set
  #' - `year_published` - published volume per year (Earliest year of publication)
  #' - `license_refs` - facet counts for license URIs of work
  #' - `journal_title` - Crossref journal title (in case of journal name change, we use the most frequent name)
  #' - `publisher` - Crossref publisher (in case of publisher name change, we use the most frequent name)
  #'
  #' To Do: switch to current potential
  if (!is.null(tt)) {
    tibble::tibble(
      issn = list(x),
      year_published = list(tt$facets$published),
      cr_issn = list(tt$facets$issn),
      license_refs = list(tt$facets$license),
      journal_title = list(tt$facets$`container-title`),
      publisher = list(tt$facets$publisher),
      category = list(tt$facets$`category-name`)
    )
  } else {
    NULL
  }
}))
my_cr_df <- purrr::map_df(jn_facets, "result")
#'get most recent publisher name and journal title
year_max <- 
  bind_rows(my_cr_df$year_published, .id = "id") %>%
  mutate(year = as.numeric(.id)) %>%
  group_by(id) %>%
  filter(year == max(year))
my_cr_df %>%
  mutate(year_max = year_max$year) %>%
  head() -> tmo

jn_facets <- purrr::map2(tmo$issn, tmo$year_max, .f = purrr::safely(function(x,y) {
  issn = x
  year = y
  tt <- rcrossref::cr_works(
    filter = c(
      issn,
      from_pub_date = year,
      until_pub_date = "2018-12-31",
      type = "journal-article"
    ),
    facet = TRUE,
    # less api traffic
    select = "DOI"
  )
  #' Parse the relevant information
  #' - `issn` - issns  found in open apc data set
  #' - `year_published` - published volume per year (Earliest year of publication)
  #' - `license_refs` - facet counts for license URIs of work
  #' - `journal_title` - Crossref journal title (in case of journal name change, we use the most frequent name)
  #' - `publisher` - Crossref publisher (in case of publisher name change, we use the most frequent name)
  #'
  #' To Do: switch to current potential
  if (!is.null(tt)) {
    tibble::tibble(
      journal_title = tt$facets$`container-title`$.id[1],
      publisher = tt$facets$publisher$.id[1]
    )
  } else {
    NULL
  }
}))

jsonlite::stream_out(my_cr_df, file("data/cr_all.json"))
#' 
my_cr_df %>% 
  select(journal_title, year_published) %>%
  unnest(year_published) %>%
  filter(.id == "2018") -> not_published 

my_cr_df %>%
  filter(!journal_title %in% not_published$journal_title)
#' scimago
sci_mago <- readr::read_delim("~/Downloads/scimagojr_2017.csv", delim = ";", locale = locale(decimal_mark = ",")) %>%
  mutate(issn = gsub("ISSN ", "", Issn)) %>%
  mutate(issn = gsub(" ", "", issn)) %>%
  tidyr::separate(issn, c("issn_1", "issn_2")) %>%
  tidyr::gather("issn_type", "issn", c("issn_1", "issn_2"))
str_sub(sci_mago$issn, 5, 4) <- "-"
publ_volume %>%
  filter(!issn %in% sci_mago$issn)
