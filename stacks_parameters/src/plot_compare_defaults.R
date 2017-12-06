#!/usr/bin/env Rscript

library(data.table)
library(ggplot2)

#############
# FUNCTIONS #
#############

ReadDefaultAndOptimisedFiles <- function(default_file, optimised_file){
    rbindlist(
        lapply(
            list(Defaults = default_file,
                 Optimised = optimised_file),
            fread),
        idcol = "type")
}

###########
# GLOBALS #
###########

set.seed(42)
popstats_defaults_file <- snakemake@input[["popstats_default"]]
popstats_optimised_file <- snakemake@input[["popstats_optimised"]]
covstats_defaults_file <- snakemake@input[["covstats_default"]]
covstats_optimised_file <- snakemake@input[["covstats_optimised"]]
samplestats_defaults_file <- snakemake@input[["samplestats_default"]]
samplestats_optimised_file <- snakemake@input[["samplestats_optimised"]]
stats_plot <- snakemake@output[['stats_plot']]
coverage_plot <- snakemake@output[['coverage_plot']]

# popstats_defaults_file <- 
#     "output/compare_defaults/default_popstats_combined.csv"
# popstats_optimised_file <- 
#     "output/compare_defaults/optimised_popstats_combined.csv"
# covstats_defaults_file <- 
#     "output/compare_defaults/default_covstats_combined.csv"
# covstats_optimised_file <- 
#     "output/compare_defaults/optimised_covstats_combined.csv"
# samplestats_defaults_file <- 
#     "output/compare_defaults/default_samplestats_combined.csv"
# samplestats_optimised_file <- 
#     "output/compare_defaults/optimised_samplestats_combined.csv"

########
# MAIN #
########

# combine the files
pop_stats <- ReadDefaultAndOptimisedFiles(popstats_defaults_file,
                                          popstats_optimised_file)
cov_stats <- ReadDefaultAndOptimisedFiles(covstats_defaults_file,
                                          covstats_optimised_file)
sample_stats <- ReadDefaultAndOptimisedFiles(samplestats_defaults_file,
                                             samplestats_optimised_file)

# melt
sample_pd <- melt(sample_stats,
                  id.vars = c("type", "rep", "sample", "m", "M", "n"),
                  measure.vars = c("assembled_loci",
                                   "polymorphic_loci",
                                   "snps"))
pop_pd <- melt(pop_stats,
               id.vars = c("type", "rep", "m", "M", "n"),
               measure.vars = c("assembled_loci",
                                "polymorphic_loci",
                                "snps"))
coverage_pd <- melt(cov_stats,
                    id.vars = c("type", "rep", "sample", "m", "M", "n"),
                    measure.vars = c("unmerged_cov", "merged_cov"))


# rename facets
facet_levels <- c(assembled_loci = "Assembled loci",
                  polymorphic_loci = "Polymorphic loci",
                  snps = "SNPs")
sample_pd[, variable := factor(plyr::revalue(variable, facet_levels),
                               levels = facet_levels)]
pop_pd[, variable := factor(plyr::revalue(variable, facet_levels),
                            levels = facet_levels)]

# rename replicate levels
orig_reps <- coverage_pd[, sort(unique(rep))]
num_reps <- gsub("[[:alpha:]]", "", orig_reps)
rep_levels <- paste("Replicate", num_reps)
names(rep_levels) <- orig_reps
coverage_pd[, rep := factor(plyr::revalue(rep, rep_levels),
                            levels = rep_levels)]

# calculate means
stat_means <- pop_pd[, .("stat_mean" = round(mean(value), 0)),
                     by = .(type, variable)]


# plot setup
Set1 <- RColorBrewer::brewer.pal(9, "Set1")
jd <- position_jitterdodge(jitter.width = 0.1, dodge.width = 0.5)
d <- position_dodge(width = 0.5)
label_func <- function(x) {gsub("[[:alpha:]]", "", x)}
gt <- paste0(
    "Polymorphic loci: ", 
    stat_means[type == "Defaults" & variable == "Polymorphic loci",
               stat_mean],
    " vs. ",
    stat_means[type == "Optimised" & variable == "Polymorphic loci",
               stat_mean],
    ". ",
    "SNPs: ",
    stat_means[type == "Defaults" & variable == "SNPs", stat_mean],
    " vs. ",
    stat_means[type == "Optimised" & variable == "SNPs", stat_mean],
    "."
)

# plot stats
sp <- ggplot(sample_pd,
       aes(x = type,
           y = value,
           fill = rep,
           colour = rep)) +
    theme(strip.placement = "outside",
          strip.background = element_blank()) +
    scale_fill_brewer(palette = "Set1",
                      guide = guide_legend(title = "Replicate"),
                      labels = label_func) +
    scale_colour_brewer(palette = "Set1",
                        guide = guide_legend(title = "Replicate"),
                        labels = label_func) +
    facet_grid(variable ~ ., scales = "free_y", switch = "y") +
    ggtitle(gt) +
    ylab(NULL) +
    xlab(NULL) +
    geom_boxplot(width = 0.4,
                 colour = alpha("black", 0.5),
                 alpha = 0.5,
                 weight = 0.5,
                 position = d,
                 outlier.size = 0,
                 outlier.colour = NA) +
    geom_point(position = jd,
               shape = 16,
               alpha = 0.5) +
    geom_point(data = pop_pd,
               aes(y = value, x = type),
               shape = 18,
               size = 3,
               colour = "black",
               position = d)

# plot coverage
cp <- ggplot(coverage_pd,
       aes(x = type,
           y = value,
           fill = variable,
           colour = variable)) +
    theme(strip.placement = "outside",
          strip.background = element_blank()) +
    scale_fill_brewer(palette = "Set1",
                      guide = guide_legend(title = NULL),
                      labels = c("Unmerged", "Merged")) +
    scale_colour_brewer(palette = "Set1",
                        guide = guide_legend(title = NULL),
                        labels = c("Unmerged", "Merged")) +
    facet_grid(rep ~ .) +
    ylab("Mean coverage") +
    xlab(NULL) +
    geom_boxplot(width = 0.4,
                 colour = alpha("black", 0.5),
                 alpha = 0.5,
                 weight = 0.5,
                 position = d,
                 outlier.size = 0,
                 outlier.colour = NA) +
    geom_point(position = jd,
               shape = 16,
               alpha = 0.5)

# write output
ggsave(filename = stats_plot,
       plot = sp,
       device = "pdf",
       width = 10,
       height = 7.5,
       units = "in")

ggsave(filename = coverage_plot,
       plot = cp,
       device = "pdf",
       width = 10,
       height = 7.5,
       units = "in")

