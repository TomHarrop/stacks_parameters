#!/usr/bin/env Rscript

library(ggplot2)
library(data.table)

###########
# GLOBALS #
###########

cov_stats_file <- snakemake@input[["covstats"]]
m_plot <- snakemake@output[["pdf"]]

########
# MAIN #
########

# read stats
coverage_stats <- fread(cov_stats_file)

# find defaults
default_M <- coverage_stats[, length(unique(m)), by = M][which.max(V1), M]
default_n <- coverage_stats[, length(unique(m)), by = n][which.max(V1), n]

# melt
coverage_pd <- melt(coverage_stats,
                    id.vars = c("m", "M", "n", "rep"),
                    measure.vars = c("unmerged_cov", "merged_cov"))

# rename replicate levels
orig_reps <- coverage_pd[, sort(unique(rep))]
num_reps <- gsub("[[:alpha:]]", "", orig_reps)
rep_levels <- paste("Replicate", num_reps)
names(rep_levels) <- orig_reps
coverage_pd[, rep := factor(plyr::revalue(rep, rep_levels),
                            levels = rep_levels)]

# set up plot
label_func <- function(x) {gsub("[[:alpha:]]", "", x)}
Set1 <- RColorBrewer::brewer.pal(9, "Set1")
m_lt <- paste0("italic('M')=='",
               label_func(default_M),
               ",' ~ italic('n')=='", label_func(default_n), "'")


# plot over m 
mp <- ggplot(coverage_pd[M == default_M], aes(x = m,
                                        y = value,
                                        fill = variable)) +
    theme(strip.placement = "outside",
          strip.background = element_blank()) +
    scale_x_discrete(labels = label_func) + 
    scale_fill_brewer(palette = "Set1",
                      guide = FALSE) +
    scale_colour_brewer(palette = "Set1",
                        guide = guide_legend(title = NULL),
                        labels = c("Unmerged", "Merged")) +
    facet_grid(rep ~ .) +
    ggtitle(parse(text = m_lt)) +
    ylab("Mean coverage") +
    xlab(
        expression(
            "Minimum number of identical, raw reads"~
                "required to create a stack ("*italic("m")*")")) +
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

# write plots
ggsave(filename = m_plot,
       plot = mp,
       device = "pdf",
       width = 10,
       height = 7.5,
       units = "in")
