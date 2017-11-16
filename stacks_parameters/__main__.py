#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import argparse
import io
import os
from pkg_resources import resource_filename
import shutil
import snakemake
import subprocess
import sys


#############
# FUNCTIONS # 
#############

# graph printing
def print_graph(snakefile, config, dag_prefix):
    # store old stdout
    stdout = sys.stdout
    # call snakemake api and capture output
    sys.stdout = io.StringIO()
    snakemake.snakemake(
        snakefile,
        config=config,
        dryrun=True,
        printdag=True)
    output = sys.stdout.getvalue()
    # restore sys.stdout
    sys.stdout = stdout
    # write output
    if shutil.which('dot'):
        svg_file = '{}.svg'.format(dag_prefix)
        # pipe the output to dot
        with open(svg_file, 'wb') as svg:
            dot_process = subprocess.Popen(
                ['dot', '-Tsvg'],
                stdin=subprocess.PIPE,
                stdout=svg)
            dot_process.communicate(input=output.encode())
    else:
        # write the file as dag
        dag_file = '{}.dag'.format(dag_prefix)
        with open(dag_file, 'wt') as file:
            file.write(output)


def main():
    # command line arguments
    parser = argparse.ArgumentParser()
    parser.add_argument(
        '--samples',
        required=True,
        help='path to the directory containing the samples reads files',
        type=str,
        dest='samples')
    parser.add_argument(
        '--popmap',
        required=True,
        help=('path to a population map file (format is "<name> TAB <pop>", '
              'one sample per line)'),
        type=str,
        dest='popmap')
    parser.add_argument(
        '-o',
        help='Output directory',
        type=str,
        dest='outdir',
        default='output')
    default_threads = min(os.cpu_count() // 2, 50)
    parser.add_argument(
        '--threads',
        help=('Number of threads. Default: %i' % default_threads),
        type=int,
        dest='threads',
        default=default_threads)

    args = vars(parser.parse_args())

    # set up logging
    outdir = args['outdir']
    log_dir = os.path.join(outdir, 'logs')
    args['log_dir'] = log_dir
    if not os.path.isdir(log_dir):
        os.makedirs(log_dir)

    # print the dag
    print_graph(snakefile, args, os.path.join(log_dir, "before"))

    # run the pipeline
    snakemake.snakemake(
        snakefile=snakefile,
        config=args,
        cores=args['threads'],
        timestamp=True)


###########
# GLOBALS #
###########

snakefile = resource_filename(__name__, 'Snakefile')

if __name__ == '__main__':
    main()
