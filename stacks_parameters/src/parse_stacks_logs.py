#!/usr/bin/env python3

import pandas
import re

#############
# FUNCTIONS #
#############

def parse_populations_log(pop_log):
    ''' Parse the populations log and return a dict of loci counts'''
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
        # return a dict
        return {'all': all_loci, 'polymorphic': polymorphic_loci}
    except:
        raise ValueError(('Header line not matched in file {0}\n'
                          'Expected: {1}').format(pop_log, header_line))


def parse_denovo_map_log(dm_log):
    '''DOCSTRING'''
    # read the log file
    with open(dm_log, 'rt') as f:
        log_lines = list(enumerate(x.rstrip('\n') for x in f.readlines()))
    # get all the ustacks blocks
    sample_starts = [i for i, line in log_lines
                     if re.match('Sample \d+ of \d+', line)]
    sample_ends = [i for i, line in log_lines
                   if 'ustacks is done' in line]
    # iterate over the blocks and parse the details
    for j in range(0, len(sample_starts)):
        sample_lines = list(line for i, line in log_lines
                            if i >= sample_starts[j] and i <= sample_ends[j])
        sample_name = re.sub('Sample \d+ of \d+ \'(?P<sn>.+)\'',
                             '\g<sn>',
                             sample_lines[0])
        unmerged_coverage = [re.sub('.+mean=(?P<mean>\d+\.\d+).+',
                                    '\g<mean>',
                                    line)
                             for line in sample_lines
                             if line.startswith(('Coverage after '
                                                 'assembling stacks:'))][0]
        merged_coverage = [re.sub('.+mean=(?P<mean>\d+\.\d+).+',
                                  '\g<mean>',
                                  line)
                           for line in sample_lines
                           if line.startswith(('Final coverage: '))][0]
        print('{}\t{}\t{}'.format(sample_name, unmerged_coverage, merged_coverage))


pop_log = 'test/rep3/populations.log'
dm_log = 'test/rep3/denovo_map.log'

loci_counts = parse_populations_log(pop_log)

