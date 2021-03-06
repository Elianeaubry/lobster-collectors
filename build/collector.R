library(gulf.utils)
library(gulf.spatial)

# Define variables to keep in the output:
vars <- c("year", "site", "collector", "condition", "comment")

# Load lobster larvae collector table:
file <- locate(file = "129_Collector_Table.csv")
x <- read.csv(file, header = TRUE, stringsAsFactors = FALSE)
names(x) <- tolower(names(x))

# Change field names:
str <- names(x)
str[str == "site_name"] <- "site"
str[str == "r_year"] <- "year"
str[str == "coll_no"] <- "collector"
str[str == "ret_comments"] <- "comment"
str[str == "cond_ret"] <- "condition"
names(x) <- str

# Collector condition table:
conditions <- c("OK", "<1/2", ">1/2", "Damaged", "Lost")
x$condition <- conditions[x$condition]

# Remove irrelevant fields:
x <- x[vars]

# Attach collector coordinates:
x$longitude <- NA
x$latitude <- NA

# Load coordinate data:
orphans <- list()
files <- locate(file = "Collector_coordinates")
for (i in 1:4){
   y <- readLines(files[i])
   y <- strsplit(y, "\t")
   n <- unlist(lapply(y, length))
   t <- table(n)
   t <- t[as.numeric(names(t)) > 5]
   t <- as.numeric(names(t[which.max(t)]))
   y <- y[n == t]

   tmp <- NULL
   for (j in 1:length(y)) tmp <- rbind(tmp, y[[j]])
   y <- as.data.frame(tmp, stringsAsFactors = FALSE)

   y <- y[, unlist(lapply(y, function(y) return(length(unique(y)) > 1)))]

   # Identify collector column:
   j <- which(unlist(lapply(y, function(y) return(all(gsub("[0-9]", "", y) == "")))))
   names(y) <- gsub(names(y)[j], "collector", names(y))
   y[, j] <- as.numeric(y[, j])

   # Identify coordinates column:
   j <- which(unlist(lapply(y, function(y) return(length(grep("^N[0-9][0-9]", y)) > 0))))
   y[,j] <- gsub("^N", "", y[,j])
   y[,j] <- gsub(" W", ",", y[,j])
   y[,j] <- gsub(" ", "", y[,j])
   y$latitude <- dmm2deg(as.numeric(unlist(lapply(strsplit(y[,j], ","), function(y) y[1]))))
   y$longitude <- -dmm2deg(as.numeric(unlist(lapply(strsplit(y[,j], ","), function(y) y[2]))))

   # Identify site column:
   j <- which(unlist(lapply(y, function(y) return(length(grep("albert", tolower(y))) > 0))))
   names(y) <- gsub(names(y)[j], "site", names(y))

   # Identify date column:
   j <- which(unlist(lapply(y, function(y) return(length(grep("[0-9]:[0-9][0-9]", y)) >= 0.5  * length(y)))))
   names(y) <- gsub(names(y)[j], "date", names(y))
   y$date <- unlist(lapply(strsplit(y$date, " "), function(y) y[1]))

   y$year <- as.numeric(unlist(lapply(strsplit(y$date[1], "-"), function(x) x[3])))
   y$year[y$year < 100] <- y$year[y$year < 100] + 2000
   
   # Remove irrelvant fields:
   y <- y[, -grep("^V[0-9]", names(y))]

   # Merge with collector table:
   ix <- match(y$collector, x$collector)
   x$longitude[ix[!is.na(ix)]] <- y$longitude[!is.na(ix)]
   x$latitude[ix[!is.na(ix)]] <- y$latitude[!is.na(ix)]
   
   if (any(is.na(ix))){
      print(y[is.na(ix), ])
      orphans <- c(orphans, list(y[is.na(ix), ]))
   } 
   
   #print(x$site2[ix[!is.na(ix)]] <- y$site[!is.na(ix)]
}

for (i in 5:length(files)){
   y <- readLines(files[i])
   y <- strsplit(y, "\t")
   y <- lapply(y, function(x) x[deblank(x) != ""])
   n <- unlist(lapply(y, length))
   y <- y[n >= 3]
   
   y <- data.frame(collector = as.numeric(unlist(lapply(y, function(x) x[1]))),
                   date = unlist(lapply(strsplit(unlist(lapply(y, function(x) x[2])), " "), function(x) x[1])),
                   time = unlist(lapply(strsplit(unlist(lapply(y, function(x) x[2])), " "), function(x) x[2])),
                   gps = unlist(lapply(y, function(x) x[3])),
                   stringsAsFactors = FALSE)

   # Format coordinates:
   y$gps <- gsub("^N", "", y$gps)
   y$gps <- gsub(" W", ",", y$gps)
   y$gps <- gsub(" ", "", y$gps)
   y$latitude <- dmm2deg(as.numeric(unlist(lapply(strsplit(y$gps, ","), function(y) y[1]))))
   y$longitude <- -dmm2deg(as.numeric(unlist(lapply(strsplit(y$gps, ","), function(y) y[2]))))
   y$year <- as.numeric(unlist(lapply(strsplit(y$date, "-"), function(x) x[3])))
   y$year[y$year < 100] <- y$year[y$year < 100] + 2000
  
   # Add coordinate data to collector table:
   ix <- which(x$year == unique(y$year))
   x$longitude[ix] <- y$longitude[match(x$collector[ix], y$collector)]
   x$latitude[ix]  <- y$latitude[match(x$collector[ix], y$collector)]
   
   # Print orphan collector data:
   y <- y[c("year", "date",  "collector", "latitude", "longitude")] 
   iy <- is.na(match(y$collector, x$collector[ix]))
   if (any(iy)){
      print(y[iy, ])
      orphans <- c(orphans, list(y[iy, ]))
   } 
   cat("\n")
}

# Compile orphan coordinate data records:
orphans <- lapply(orphans, function(x) x[c("year", "collector", "longitude", "latitude")])
tmp <- NULL
for (i in 1:length(orphans)) tmp <- rbind(tmp, orphans[[i]])
orphans <- tmp

# Write to file:
file <- paste0(strsplit(file, "/raw")[[1]][1], "/collector.csv")

write.table(x, file = file, col.names = TRUE, row.names = FALSE, sep = ",")

