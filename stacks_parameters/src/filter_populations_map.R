#!/usr/bin/env Rscript

library(data.table)

popmap_file <- snakemake@input[["popmap"]]
sample_dir <- snakemake@params[["sample_dir"]]
stats_file <- snakemake@input[["stats"]]
filtered_population_map <- snakemake@output[["map"]]

# read the popmap
popmap <- fread(popmap_file,
                header = FALSE,
                col.names = c("sample_name", "population"))

# find paths for sample files
sample_files <- list.files(path = sample_dir, full.names = TRUE)
file_names <- data.table(filepath = sample_files,
                         sample_name = sapply(sample_files, function(x)
                             strsplit(basename(x), ".", fixed = TRUE)[[1]][1]))
all_samples <- merge(popmap, file_names, all.x = TRUE, all.y = FALSE)
all_samples[, bn := basename(filepath)]

# read the stats results
stats <- fread(stats_file)
stats[, bn := basename(filename)]

# merge the read counts
samples_with_readcount <- merge(all_samples,
      stats[, .(bn, reads = n_scaffolds)],
      by = "bn",
      all.x = TRUE,
      all.y = FALSE)

# filter samples by read count
filter <- samples_with_readcount[, quantile(reads, 0.2, na.rm = TRUE)]
filtered_samples <- samples_with_readcount[!is.na(reads)][reads > filter]

fwrite(filtered_samples[, .(sample_name, population)],
       filtered_population_map,
       col.names = FALSE,
       sep = "\t")
       

