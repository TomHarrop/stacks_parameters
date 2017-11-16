#!/usr/bin/env python3

import argparse
import gzip
import pandas
from Bio import SeqIO
import tempfile
import os


def main():
    # parse command line
    parser = argparse.ArgumentParser()
    parser.add_argument('catalog')
    parser.add_argument('fasta')
    args = vars(parser.parse_args())
    tags_file = args['catalog']
    output_fasta = args['fasta']

    tags_file = 'denovo_map/batch_1.catalog.tags.tsv.gz'
    output_fasta = '/Volumes/userdata/staff_users/tomharrop/test.fasta'

    # read tsv into a data frame
    with gzip.open(tags_file, 'rt') as f:
        catalog = pandas.read_table(f, header=None, comment="#")

    # write columns 3 and 10 to a temporary file
    tmp = tempfile.mkstemp(suffix='.tab')[1]
    catalog.to_csv(tmp, sep='\t', columns=[2, 9], header=False, index=False)

    # convert the temporary file into fasta
    SeqIO.convert(tmp, 'tab', output_fasta, 'fasta')

    # tidy up
    os.remove(tmp)


if __name__ == '__main__':
    main()
