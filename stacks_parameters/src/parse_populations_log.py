#!/usr/bin/env python3

import pandas

def parse_populations_log(pop_log):
    '''
    Parse the populations log and return a dict of loci counts.

    This function returns the same values as the grep/sed commands provided by
    Josephine Paris, which were supposedly used in the Parameter Space paper
    (10.1111/2041-210X.12775).

    # Number of loci:
    # Reads every locus regardless of population (and pop map specified) don't
    # have to provide ‘defaultpop'
    `cat batch_1.haplotypes.tsv | sed '1d' | wc -l`

    # Polymorphic loci:
    # Only takes the locus ID but by sorting them means no need to specify a
    # particular pop with a popmap
    `cat batch_1.sumstats.tsv | grep -v "^#" | cut -f 2 | sort -n | uniq | wc -l`

    # SNPs:
    # Takes the locus ID and the SNP column position and works regardless of
    # which pop the locus was found in
    `cat batch_1.sumstats.tsv | grep -v "^#" | cut -f 2,5 | sort -n | uniq | wc -l`
    '''
    with open(pop_log, 'rt') as f:
        header_line = ('# Distribution of the number of SNPs '
                       'per catalog locus after filtering.')
        # navigate to the part of the file we want
        for line in f:
            if line.rstrip('\n') == header_line:
                # read the table
                log_table = pandas.read_table(
                    f,
                    sep='\t',
                    header=0,
                    skipfooter=2,
                    engine='python')
    try:
        # count the loci
        all_loci = log_table.sum(axis=0)['Number loci']
        polymorphic_loci = log_table[
            log_table['# Number SNPs'] > 0].sum(axis=0)['Number loci']
        # count the number of SNPs
        snps = sum(log_table['# Number SNPs'] * log_table['Number loci'])
        # return a dict
        return {'loci': all_loci,
                'polymorphic_loci': polymorphic_loci,
                'snps': snps}
    except:
        raise ValueError(('Header line not matched in file {0}\n'
                          'Expected: {1}').format(pop_log, header_line))


def main():
    pop_log = 'test/rep3/populations.log'
    loci_counts = parse_populations_log(pop_log)


if __name__ == '__main__':
    main()