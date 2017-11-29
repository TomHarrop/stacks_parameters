library(data.table)
library(ggplot2)

sample_pd <- melt(sample_stats, id.vars = "sample")
pop_pd <- data.table(t(population_stats), keep.rownames = TRUE)
setnames(pop_pd, c("rn", "V1"), c("variable", "value"))

sample_pd[, m := 1]
pop_pd[, m := 1]

Set1 <- RColorBrewer::brewer.pal(9, "Set1")

ggplot(sample_pd, aes(x = m, y = value)) +
    facet_grid(variable ~ ., scales = "free_y") +
    geom_boxplot(fill = alpha(Set1[1], 0.5)) +
    geom_point(data = pop_pd, aes(y = value, x = m), colour = Set1[2])
