#' 2a) How thoroughly are these journals indexed in major bibliometric databases (Web of Science, Scopus, PubMed)?
library(tidyverse)
# reverse-flip journals
rev_flip <- readxl::read_xlsx("data/master_list.xlsx", sheet = 2)
# add issn variants
issn_mapping <- readr::read_csv("data/issn_matching_cr.csv")
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
                       "1759-3077", "Bulletin of Italian Politics", "2324-8823",
                       "1759-3077", "Bulletin of Italian Politics", "2324-8831")
issn_mapping <- bind_rows(issn_mapping, changed_jns) 
rev_flip_issn <- rev_flip %>%
  select(issn, journal_name) %>%
  left_join(issn_mapping, by = "issn")
# nlm indexed journals
nlm <- readr::read_csv("data/nlm_list.csv") %>%
  gather(1:3, key = "issn_type", value = "issn") %>%
  filter(!is.na(issn))
nlm %>%
  filter(issn %in% rev_flip_issn$issn_cr | issn %in% rev_flip_issn$issn) %>%
  distinct(title)
# scopus
scopus <- readxl::read_xlsx("data/ext_list_April_2018_2017_Metrics.xlsx") %>% 
  gather(key = "issn_type", value = "issn", `Print-ISSN`, `E-ISSN`) %>%
  filter(!is.na(issn)) -> scopus_jns
stringi::stri_sub(scopus_jns$issn,5, 4) <- "-" 
scopus_jns %>% 
  select(1:3, `Title history indication`, issn) %>% 
  filter(issn %in% rev_flip_issn$issn_cr | issn %in% rev_flip_issn$issn) %>% 
  distinct(`Sourcerecord id`, .keep_all = TRUE)
# wos
wos <- readr::read_csv("data/jcr.csv") %>%
  filter(!is.na(ISSN))
#' add tag to reverse-flip journal dataset
rev_flip_issn %>% 
  mutate(Scopus = ifelse(issn_cr %in% scopus_jns$issn | issn %in% scopus_jns$issn, TRUE, FALSE)) %>%
  mutate(JCR = ifelse(issn %in% wos$ISSN | issn_cr %in% wos$ISSN, TRUE, FALSE)) %>%
  mutate(MEDLINE = ifelse(issn_cr %in% nlm$issn | issn %in% nlm$issn, TRUE, FALSE)) %>% 
  mutate(Crossref = ifelse(!is.na(journal_title), TRUE, FALSE)) -> indexing_jns
indexing_jns %>% 
  select(-issn_cr, -journal_title) %>%
  gather(3:6, key = "source", value = "indexed") %>%
  filter(indexed == TRUE) %>% 
  distinct() %>% 
  select(-indexed) -> index_df
#' export
write_csv(index_df, "data/indexing_coverage.csv")
