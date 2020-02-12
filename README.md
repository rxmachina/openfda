# openfda

Explore and analyze FDA Drug Adverse Event (FAERS) data

FDA Drug Adverse Event Overview
https://open.fda.gov/apis/drug/event/

FDA Adverse Event Reporting System (FAERS) Quarterly Data Extract Files
https://fis.fda.gov/extensions/FPD-QDE-FAERS/FPD-QDE-FAERS.html

openFDA github repository
https://github.com/FDA/openfda/

------------------------------------------------------------------------------------------

1.  Are different adverse events reported in different countries?

Use:  REAC19Q3.txt, DEMO19Q3.txt -> join on PRIMARYID

Data:  foreach case, emit DEMO.OCCR_COUNTRY, REAC.PT

Analysis:  frequency of each event-type in each country (profile)
	   frequency profile comparisons across countries
	   distance matrices
	   classification/clustering

