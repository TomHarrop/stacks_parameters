#!/usr/bin/env Rscript

library(data.table)

#############
# FUNCTIONS #
#############

ParsePopMap <- function(popmap) {
    my_pops <- fread(popmap,
                     header = FALSE,
                     col.names = c("sample", "population"))
    my_pops[, sort(unique(sample))]
}

FindSampleResultsFiles <- function(stacks_dir, samples) {
    my_samples <- samples
    names(my_samples) <- my_samples
    my_sample_files <- lapply(my_samples, function(x)
        list.files(stacks_dir,
                   pattern = paste0(x, ".")))
    my_parsed_files <- lapply(my_sample_files, function(x)    
        data.table(
            tag_file = grep("tags.tsv.gz$", x, value = TRUE),
            alleles_file = grep("alleles.tsv.gz$", x, value = TRUE),
            snp_file = grep("snps.tsv.gz$", x, value = TRUE)))
    rbindlist(my_parsed_files, idcol = "sample")}

ParseIndividualTags <- function(stacks_dir, tag_file) {
    # Number of assembled loci:
    # for i in *.tags.tsv.gz; do zcat $i | cut -f 3 | tail -n 1; done
    my_tags <- fread(paste0("zgrep -v '^#' ", stacks_dir, "/", tag_file),
                     header = FALSE,
                     sep = "\t")
    my_tags[, length(unique(V3))]
}

ParseIndividualTags <- function(stacks_dir, allele_file) {
    # Number of polymorphic loci:
    # for i in *.alleles.tsv.gz; do zcat $i | grep -v "^#" | cut -f 3 | sort | uniq | wc -l; done
    my_alleles <- fread(paste0("zgrep -v '^#' ", stacks_dir, "/", allele_file),
                        header = FALSE,
                        sep = "\t")
    my_alleles[, length(unique(V3))]
}

ParseIndividualSNPs <- function(stacks_dir, snp_file) {
    # Number of SNPs:
    # for i in *.snps.tsv.gz; do zcat $i | grep -v "^#" | cut -f 5 | grep -c "“E"; done
    my_snps <- fread(paste0("zgrep -v '^#' ", stacks_dir, "/", snp_file),
                     header = FALSE,
                     sep = "\t")
    dim(my_snps[V5 == "E"])[1]
}

ParsePopulationsStats <- function(stacks_dir){
    # Number of loci
    # cat batch_1.haplotypes.tsv | sed '1d' | wc -l 
    # Reads every locus regardless of population (and pop map specified) don't
    # have to provide ‘defaultpop'
    # Polymorphic loci
    # cat batch_1.sumstats.tsv | grep -v "^#" | cut -f 2 | sort -n | uniq | wc -l 
    # Only takes the locus ID but by sorting them means no need to specify a
    # particular pop with a popmap
    # SNPs
    # cat batch_1.sumstats.tsv | grep -v "^#" | cut -f 2,5 | sort -n | uniq | wc -l 
    # Takes the locus ID and the SNP column position and works regardless of
    # which pop the locus was found in
    
    # check sumstats exists
    if (length(list.files(stacks_dir,
                          pattern = "populations.sumstats.tsv")) == 0) {
        stop(paste("populations.sumstats.tsv not found in", stacks_dir))
    }
    
    # check if haplotypes exists
    if (length(list.files(stacks_dir,
                          pattern = "populations.haplotypes.tsv")) == 0) {
        stop(paste("populations.haplotypes.tsv not found in", stacks_dir))
    }
    
    # parse hapstats
    my_hapstats <- fread(paste0("grep -v '^#' ",
                                stacks_dir,
                                "/populations.haplotypes.tsv"))
    my_loci <- my_hapstats[, length(unique(V1))]
    
    # parse sumstats
    my_sumstats <- fread(paste0("grep -v '^#' ",
                                stacks_dir,
                                "/populations.sumstats.tsv"))
    my_polymorphic_loci <- my_sumstats[, length(unique(V1))]
    my_snps <- dim(unique(my_sumstats, by = c("V1", "V4")))[1]
    
    # return stats
    data.table(
        assembled_loci = my_loci,
        polymorphic_loci = my_polymorphic_loci,
        snps = my_snps
    )
    }

###########
# GLOBALS #
###########

popmap <- "output/filtering/replicate_3_popmap.txt"
stacks_dir <- "test/rep3"

########
# MAIN #
########

# get the populations summary
population_stats <- ParsePopulationsStats(stacks_dir)

# get a list of samples
all_samples <- ParsePopMap(popmap)

# parse the file locations
sample_files <- FindSampleResultsFiles(stacks_dir, all_samples)

# run the counts
sample_stats <- sample_files[
    , .(assembled_loci = ParseIndividualTags(stacks_dir,
                                             tag_file),
        polymorphic_loci = ParseIndividualTags(stacks_dir,
                                               alleles_file),
        snps = ParseIndividualSNPs(stacks_dir,
                                   snp_file)),
    by = sample]


