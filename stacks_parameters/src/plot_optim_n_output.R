#!/usr/bin/env Rscript

library(data.table)
library(ggplot2)

###########
# GLOBALS #
###########

set.seed(42)
pop_stats_file <- snakemake@input[["popstats"]]
sample_stats_file <- snakemake@input[["samplestats"]]
default_M <- snakemake@params[["M"]]
default_m <- snakemake@params[["m"]]
n_plot <- snakemake@output[["n"]]

# pop_stats_file <- "output/stats_n/popstats_combined.csv"
# sample_stats_file <- "output/stats_n/samplestats_combined.csv"    
# default_M <- 'M3'
# default_m <- 'm3'

########
# MAIN #
########

pop_stats <- fread(pop_stats_file)
sample_stats <- fread(sample_stats_file)

# pick the winner
max_n <- pop_stats[M == default_M & m == default_m,
          mean(unique(polymorphic_loci)),
          by = n][which.max(V1), n]

# go long
sample_pd <- melt(sample_stats,
                  id.vars = c("m", "M", "n", "rep"),
                  measure.vars = c("assembled_loci",
                                   "polymorphic_loci",
                                   "snps"))
pop_pd <- melt(pop_stats,
               id.vars = c("m", "M", "n", "rep"),
               measure.vars = c("assembled_loci",
                                "polymorphic_loci",
                                "snps"))

# rename facets
facet_levels <- c(assembled_loci = "Assembled loci",
                  polymorphic_loci = "Polymorphic loci",
                  snps = "SNPs")
sample_pd[, variable := factor(plyr::revalue(variable, facet_levels),
                               levels = facet_levels)]
pop_pd[, variable := factor(plyr::revalue(variable, facet_levels),
                            levels = facet_levels)]


# plot setup
Set1 <- RColorBrewer::brewer.pal(9, "Set1")
jd <- position_jitterdodge(jitter.width = 0.1, dodge.width = 0.5)
d <- position_dodge(width = 0.5)
label_func <- function(x) {gsub("[[:alpha:]]", "", x)}
n_lt <- paste0("italic('m')=='",
               label_func(default_m),
               ",' ~ italic('M')=='", label_func(default_M), ". ",
               "Maximum number of polymorphic loci at' ~ italic('r')=='0.8:'",
               "~ italic('n')==", label_func(max_n))

# plot over m
np <- ggplot(sample_pd[m == default_m & M == default_M],
       aes(x = n,
           y = value,
           fill = rep,
           colour = rep)) +
    theme(strip.placement = "outside",
          strip.background = element_blank()) +
    scale_x_discrete(labels = label_func) + 
    scale_fill_brewer(palette = "Set1",
                      guide = FALSE) +
    scale_colour_brewer(palette = "Set1",
                        guide = guide_legend(title = "Replicate"),
                        labels = label_func) +
    facet_grid(variable ~ ., scales = "free_y", switch = "y") +
    ggtitle(parse(text = n_lt)) +
    ylab(NULL) +
    xlab(
        expression(
            "Number of mismatches allowed between loci when" ~
            "building the catalog ("*italic("n")*")")) +
    geom_boxplot(alpha = 0.5,
                 width = 0.2,
                 colour = alpha("black", 0.5),
                 weight = 0.5,
                 outlier.size = 0,
                 outlier.colour = NA,
                 position = d) +
    geom_point(position = jd,
               alpha = 0.8) +
    geom_point(data = pop_pd[m == default_m & M == default_M],
               aes(y = value, x = n),
               shape = 18,
               size = 3,
               colour = "black",
               position = d)

ggsave(filename = n_plot,
       plot = np,
       device = "pdf",
       width = 10,
       height = 7.5,
       units = "in")

