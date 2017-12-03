library(data.table)
library(ggplot2)

###########
# GLOBALS #
###########

set.seed(42)
pop_stats_file <- snakemake@input[["popstats"]]
sample_stats_file <- snakemake@input[["samplestats"]]
M_plot <- snakemake@output[["M"]]
m_plot <- snakemake@output[["m"]]

# dev
#pop_stats_file <- "output/stats_Mm/popstats_combined.csv"
#sample_stats_file <- "output/stats_Mm/samplestats_combined.csv"

########
# MAIN #
########

pop_stats <- fread(pop_stats_file)
sample_stats <- fread(sample_stats_file)

# what were the defaults
default_M <- pop_stats[, length(unique(m)), by = M][which.max(V1), M]
default_m <- pop_stats[, length(unique(M)), by = m][which.max(V1), m]
default_n <- pop_stats[, length(unique(m)), by = n][which.max(V1), n]

# pick the winners
max_m <- pop_stats[M == default_M, mean(unique(polymorphic_loci)), by = m][
    which.max(V1), m]
max_M <- pop_stats[m == default_m, mean(unique(polymorphic_loci)), by = M][
    which.max(V1), M]

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
m_lt <- paste0("italic('M')=='",
               label_func(default_M),
               ",' ~ italic('n')=='", label_func(default_n), ". ",
               "Maximum number of polymorphic loci at' ~ italic('r')=='0.8:'",
               "~ italic('m')==", label_func(max_m))
M_lt <- paste0("italic('m')=='",
               label_func(default_m),
               ",' ~ italic('n')=='", label_func(default_n), ". ",
               "Maximum number of polymorphic loci at' ~ italic('r')=='0.8:'",
               "~ italic('M')==", label_func(max_M))

# plot over m
mp <- ggplot(sample_pd[M == default_M], aes(x = m,
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
    ggtitle(parse(text = m_lt)) +
    ylab(NULL) +
    xlab(
        expression(
            "Minimum number of identical, raw reads"~
                "required to create a stack ("*italic("m")*")")) +
    geom_boxplot(alpha = 0.5,
                 width = 0.2,
                 colour = alpha("black", 0.5),
                 weight = 0.5,
                 outlier.size = 0,
                 outlier.colour = NA,
                 position = d) +
    geom_point(position = jd,
               alpha = 0.8) +
    geom_point(data = pop_pd[M == default_M],
               aes(y = value, x = m),
               shape = 18,
               size = 3,
               colour = "black",
               position = d)

# plot over M
Mp <- ggplot(sample_pd[m == default_m], aes(x = M,
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
    ggtitle(parse(text = M_lt)) +
    ylab(NULL) +
    xlab(
        expression(
            "Number of mismatches allowed between loci when processing"~
                "a single individual ("*italic("M")*")")) +
    geom_boxplot(alpha = 0.5,
                 width = 0.2,
                 colour = alpha("black", 0.5),
                 weight = 0.5,
                 outlier.size = 0,
                 outlier.colour = NA,
                 position = d) +
    geom_point(position = jd,
               alpha = 0.8) +
    geom_point(data = pop_pd[m == default_m],
               aes(y = value, x = M),
               shape = 18,
               size = 3,
               colour = "black",
               position = d)

# write plots
ggsave(filename = m_plot,
       plot = mp,
       device = "pdf",
       width = 10,
       height = 7.5,
       units = "in")

ggsave(filename = M_plot,
       plot = Mp,
       device = "pdf",
       width = 10,
       height = 7.5,
       units = "in")

