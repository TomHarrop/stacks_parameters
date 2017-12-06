#!/usr/bin/env Rscript

library(data.table)

##########
# GLOBALS #
###########

input_files <- unique(unlist(snakemake@input))
output_files <- snakemake@output[["combined"]]

########
# MAIN #
########

# set names
names(input_files) <- gsub("_[[:alnum:]]+.csv", "", basename(input_files))

# fread and combine
stacks_data <- rbindlist(lapply(input_files, fread), idcol = "stacks_run")

# split stacks_run
stacks_data[, c("m", "M", "n", "rep") := tstrsplit(stacks_run, split = "_")]

# write results
fwrite(stacks_data, output_files)


