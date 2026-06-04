Hello!

This is Lucas. I hope you read this before opening the files and getting into the nitty-gritty.

A quick rundown:

The data_pipeline folder contains the R programs (a markdown and a pure R file) that fetches
raw datasets from The NHL public web API at api-web.nhle.com from fetch_games.Rmd. "Export CSV.R"
exports the raw data after formatting as an CSV file.

Moreover, the "sql" folder contains the schemas and queries for uploading the datasets onto a
postgresql database.

In the analysis folder, it contains my vertical slice originally to check if the research was
actually worth doing and if there is any signals. The file "Confound" contains my actual analysis
and results in which I eventually concluded with power BI.


Thanks for reading!
