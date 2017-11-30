library(data.table)
library(ggplot2)

###########
# GLOBALS #
###########

set.seed(42)
pop_stats_file <- "test/pop_stats.csv"
sample_stats_file <- "test/sample_stats.csv"

########
# MAIN #
########

pop_stats <- fread(pop_stats_file)
sample_stats <- fread(sample_stats_file)

# go long
sample_pd <- melt(sample_stats, id.vars = "sample")
pop_pd <- data.table(t(pop_stats), keep.rownames = TRUE)
setnames(pop_pd, c("rn", "V1"), c("variable", "value"))

# dummy x axis variables
sample_pd <- rbind(copy(sample_pd)[, m := "m1"],
                   copy(sample_pd)[, m := "m2"])
pop_pd <- rbind(copy(pop_pd)[, m := "m1"],
                copy(pop_pd)[, m := "m2"])


Set1 <- RColorBrewer::brewer.pal(9, "Set1")

ggplot(sample_pd, aes(x = m, y = value)) +
    theme(strip.placement = "outside",
          strip.background = element_blank()) +
    facet_grid(variable ~ ., scales = "free_y", switch = "y") +
    ylab(NULL) +
    xlab("Minimum number of identical, raw reads required to create a stack") +
    geom_boxplot(fill = alpha(Set1[1], 0.5),
                 width = 0.2,
                 colour = alpha("black", 0.5),
                 weight = 0.5) +
    geom_point(colour = Set1[1],
               position = position_jitter(width = 0.05)) +
    geom_point(data = pop_pd, aes(y = value, x = m),
               colour = Set1[2])
