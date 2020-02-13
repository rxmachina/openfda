#!R
#--------------------------------------------------------------------------------
#
# Example analysis of FAERS Drug Event data
#
# FDA Adverse Event Reporting System (FAERS) Quarterly Data Extract Files
# https://fis.fda.gov/extensions/FPD-QDE-FAERS/FPD-QDE-FAERS.html
#
# Question:  Are different adverse events reported in different countries?
#
# Source data:  2019Q3 data files (REAC19Q3.txt, DEMO19Q3.txt)
#
#     https://fis.fda.gov/content/Exports/faers_ascii_2019Q3.zip
#
# Dataset:  for each case, -> join on sorted primaryid, extract DEMO.OCCR_COUNTRY, REAC.PT
#
#     % join -t $'\t' -o 2.1,2.25,1.3 REAC19Q3.tab.sorted DEMO19Q3.tab.sorted > REAC+DEMO19Q3.tab.min.sorted &
#
#     REF:  https://shapeshed.com/unix-join/
#
# Analysis:  normalize country counts by total events -> frequency of each event-type in each country (profile)
#	     heatmap of countries vs events
#	     classification/clustering
#
#--------------------------------------------------------------------------------

# read in raw data
#
setwd("~/Documents/mine/pro/AZ/faers_ascii_2019Q3/ascii/")
events.country <- read.delim("REAC+DEMO19Q3.tab.min.sorted")

# pivot into count matrix
#
library(reshape)
ev.counts <- cast(melt(events.country), pt ~ occr_country)  # event by country frequency matrix
pt <- as.character(ev.counts[,1])
ev.counts <- ev.counts[,-1]
row.names(ev.counts) <- pt

# for clustering, need to normalize data, since raw counts data are not ideal for standard metrics (distance/dissim/corr)
#
# basic approach:  convert to normalized freq. (divide row for each country by total events in each country)
#
ev.freq <- sweep(ev.counts, 1, rowSums(ev.counts), FUN = '/')


# heatmap
#
library(RColorBrewer)
ev.heatmap <- heatmap(as.matrix(ev.freq), col= colorRampPalette(brewer.pal(8, "Blues"))(25))


# NOTE:  better approaches could be to explore other:
#
# transformations (scale, variance)
# measures (correlation, Jaccard, Bray-Curtis)
# model-based estimates (Poisson, probability estimates e.g. using philentropy package, https://rdrr.io/cran/philentropy/man/estimate.probability.html)

#--------------------------------------------------------------------------------

# extract "distinct" event terms for top 8 reporting countries (US, CA, JP, DE, FR, GB, IT, BR)
#
ev.top <- ev.freq[ev.heatmap$rowInd,ev.heatmap$colInd[1:8]]

# determine frequency cutoff for "distinct" terms
#
plot(hist(as.vector(as.matrix(ev.top))), main="Drug Event Frequency Histogram", xlab="Event frequency within a country", ylab="Counts", col="skyblue")

# filter list of events with freq > cutoff
#
cutfreq <- 0.9
ev.distinct <- ev.top[apply(ev.top, 1, function(x){ any(x > cutfreq); }),]


# NOTE:  better approaches could be to use:
#
# bi-clustering, discriminant analysis to identify hallmark drug events for each country
