library(data.table)
library(ggplot2)

###########
# GLOBALS #
###########

set.seed(42)
pop_stats_file <- "output/stats_Mm/popstats_combined.csv"
sample_stats_file <- "output/stats_Mm/samplestats_combined.csv"

########
# MAIN #
########

pop_stats <- fread(pop_stats_file)
sample_stats <- fread(sample_stats_file)

# pick the winner
pop_stats[M == "M2"][which.max(polymorphic_loci)]
pop_stats[m == "m3"][which.max(polymorphic_loci)]


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



# plots
Set1 <- RColorBrewer::brewer.pal(9, "Set1")

# plot over m with M=M2, e.g. sample_pd[, length(unique(m)), by = M]
ggplot(sample_pd[M == "M2"], aes(x = m, y = value)) +
    theme(strip.placement = "outside",
          strip.background = element_blank()) +
    facet_grid(variable ~ ., scales = "free_y", switch = "y") +
    ylab(NULL) +
    xlab("Minimum number of identical, raw reads required to create a stack") +
    geom_boxplot(fill = alpha(Set1[1], 0.5),
                 width = 0.2,
                 colour = alpha("black", 0.5),
                 weight = 0.5,
                 outlier.size = 0,
                 outlier.colour = NA) +
    geom_point(colour = Set1[1],
               position = position_jitter(width = 0.05)) +
    geom_point(data = pop_pd[M == "M2"], aes(y = value, x = m),
               colour = Set1[2])

# plot over M with m=m3, e.g. sample_pd[, length(unique(M)), by = m]
ggplot(sample_pd[m == "m3"], aes(x = M, y = value)) +
    theme(strip.placement = "outside",
          strip.background = element_blank()) +
    facet_grid(variable ~ ., scales = "free_y", switch = "y") +
    ylab(NULL) +
    xlab("Number of mismatches allowed between loci when processing a single individual") +
    geom_boxplot(fill = alpha(Set1[1], 0.5),
                 width = 0.2,
                 colour = alpha("black", 0.5),
                 weight = 0.5,
                 outlier.size = 0,
                 outlier.colour = NA) +
    geom_point(colour = Set1[1],
               position = position_jitter(width = 0.05)) +
    geom_point(data = pop_pd[m == "m3"], aes(y = value, x = M),
               colour = Set1[2])

