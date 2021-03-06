# Define variables to keep in the output:
vars <- c("year", "site", "longitude", "latitude", "date.deployed", "date.retrieved", "comment")

# Load lobster collector site table:
x <- read.csv("data/raw/129_Site_Table_08_18.csv", header = TRUE, stringsAsFactors = FALSE, fileEncoding = "Windows-1252")
names(x) <- tolower(names(x))

# Change field names:
str <- names(x)
str[str == "site_name"] <- "site"
str[str == "c_enter_lat"] <- "latitude"
str[str == "c_enter_lon"] <- "longitude"
str[str == "comments"] <- "comment"
names(x) <- str

# Correct coordinate fields:
x$longitude <- -abs(x$longitude)
x$latitude  <- abs(x$latitude)

# Format date fields:
x$date.deployed  <- as.character(as.Date(paste0(x$s_year, "-", x$s_month, "-", x$s_day)))
x$date.retrieved <- as.character(as.Date(paste0(x$r_year, "-", x$r_month, "-", x$r_day)))
x$year <- as.numeric(substr(x$date.deployed, 1, 4))

# Remove irrelevant fields:
x <- x[vars]

write.table(x, file = "/Users/crustacean/Desktop/lobster-collectors/data/site-year.csv", col.names = TRUE, row.names = FALSE, sep = ",")
