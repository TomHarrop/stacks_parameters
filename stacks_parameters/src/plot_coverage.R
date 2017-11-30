#!/usr/bin/env Rscript

library(ggplot2)
library(data.table)

###########
# GLOBALS #
###########

cov_stats_file <- "test/coverage_stats.csv"

########
# MAIN #
########

# read stats
coverage_stats <- fread(cov_stats_file)

# melt
coverage_pd <- melt(coverage_stats, id.vars = c("sample"))

# dummy m
coverage_pd <- rbind(copy(coverage_pd)[, m := "m1"],
                     copy(coverage_pd)[, m := "m2"])


# plot
Set1 <- RColorBrewer::brewer.pal(9, "Set1")
ggplot(coverage_pd, aes(x = m,
                        y = value,
                        fill = variable)) +
    theme(strip.placement = "outside",
          strip.background = element_blank()) +
    ylab("Coverage") +
    xlab("Minimum number of identical, raw reads required to create a stack") +
    scale_fill_brewer(palette = "Set1") +
    scale_colour_brewer(palette = "Set1") +
    geom_boxplot(width = 0.2,
                 alpha = 0.5,
                 colour = alpha("black", 0.5),
                 weight = 0.5,
                 position = position_dodge(width = 0.5),
                 outlier.size = 0,
                 outlier.colour = NA) +
    geom_point(mapping = aes(colour = variable),
               position = position_jitterdodge(jitter.width = 0.05,
                                               dodge.width = 0.5))

