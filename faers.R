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
# Source data:     https://fis.fda.gov/content/Exports/faers_ascii_2019Q3.zip
#
#        REAC19Q3.txt - adverse events:  452K entries / 56MB
#        DEMO19Q3.txt - demographics:  1.5M entries / 63MB
#
# Dataset:  for each case -> join on sorted (numerical) primaryid, extract DEMO.OCCR_COUNTRY, REAC.PT
#
/usr/bin/time -l join -t '$' -o 1.1,1.25,2.3 \
      <(unzip -p ../faers_ascii_2019Q3.zip ascii/DEMO19Q3.txt | sort -t'$' -n) \
      <(unzip -p ../faers_ascii_2019Q3.zip ascii/REAC19Q3.txt | sort -t'$' -n) \
      | perl -pe 's/\$/\t/g; s/\cM//' | gzip -c > REAC+DEMO19Q3.tab.min.sorted.gz &
#
#          results in 1.5M compressed rows in ~8s real, ~900MB max rss
#
# Analysis:  normalize country counts by total events -> frequency of each event-type in each country (profile)
#	     heatmap of countries vs events
#	     classification/clustering
#
#--------------------------------------------------------------------------------
# read in raw data
#
events.country <- read.delim("REAC+DEMO19Q3.tab.min.sorted.gz")

# pivot into count matrix
#
library(reshape)
ev.counts <- cast(melt(events.country), pt ~ occr_country)  # event by country frequency matrix
pt <- as.character(ev.counts[,1])
ev.counts <- ev.counts[,-1]
row.names(ev.counts) <- pt

#--------------------------------------------------------------------------------
# transform data for clustering since raw counts data are not ideal for standard metrics (distance/dissim/corr)
#
# basic approach:  convert to normalized freq. (divide row for each country by total for each event type)
#
ev.freq <- sweep(ev.counts, 1, rowSums(ev.counts), FUN = '/')

# heatmap
#
library(RColorBrewer)
ev.heatmap <- heatmap(as.matrix(ev.freq), col= colorRampPalette(brewer.pal(8, "Blues"))(25))
ev.freq <- ev.freq[ev.heatmap$rowInd,ev.heatmap$colInd]  # re-order data as per clustering

# NOTE:  better approaches could be to explore other:
#
# transformations (scale, variance)
# measures (correlation, Jaccard, Bray-Curtis)
# model-based estimates (Poisson, probability estimates e.g. using philentropy package, https://rdrr.io/cran/philentropy/man/estimate.probability.html)

#--------------------------------------------------------------------------------
# determine frequency cutoff for "distinct" terms
#
ev.vec <- as.vector(as.matrix(ev.freq))
ev.hist <- hist(ev.vec[ ev.vec != 0], main="Drug Event Frequency Histogram", xlab="Event frequency for each country", ylab="Counts", col="skyblue")  # exclude zero counts

cutfreq <- 0.9  # choose cutoff
lines(c(cutfreq,cutfreq),c(0,10000),col="red",lty=2,lwd=2)  # show cutoff freq (dashed red line)

# filter list of events with freq > cutoff
#
ev.distinct <- ev.freq[apply(ev.freq, 1, function(x){ any(x > cutfreq); }),]
write.table(ev.distinct, file="events-distinct.txt", sep="\t")

# extract "distinct" event terms for top 8 reporting countries (US, CA, JP, DE, FR, GB, IT, BR)
ev.top.distinct <- ev.distinct[,1:8];
#write.table(ev.top.distinct, file="events-distinct-top8.txt", sep="\t")


# NOTE:  better approaches could be to use:
#
# bi-clustering, discriminant analysis to identify hallmark drug events for each country
