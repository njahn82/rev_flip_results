# cwts test
library(tidyverse)
my_df <- readxl::read_xlsx("data/master_list.xlsx", sheet = 2) %>%
  mutate(issn = ifelse(issn == "0037-8615", "1405-213X", issn)) %>%
  # create id column
  mutate(id = issn)
#' #' get all issn variants. for this aim, we use issn matching, whih can be freely downloaded from here
#' #' add to dataset
cwts <- readxl::read_xlsx("data/CWTS Journal Indicators May 2018.xlsx")
cwts %>%
  gather(3:4, key = "issn_type", value = "issn") -> cwts_enriched
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
issn_mapping %>%
  inner_join(cwts_enriched, by = c("issn_cr" = "issn")) %>%
  inner_join(my_df, by = "issn") -> cwts_flipped
readr::write_csv(cwts_flipped, "data/cwts_jn_flipped.csv")
