#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import argparse
import io
import os
import pathlib
from pkg_resources import resource_filename
import shutil
import snakemake
import subprocess
import sys


#############
# FUNCTIONS # 
#############

# coloured text for arguments
class colour:
    PURPLE = '\033[95m'
    CYAN = '\033[96m'
    DARKCYAN = '\033[36m'
    BLUE = '\033[94m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'
    END = '\033[0m'


# graph printing
def print_graph(snakefile, config, dag_prefix):
    # store old stdout
    stdout = sys.stdout
    # call snakemake api and capture output
    sys.stdout = io.StringIO()
    snakemake.snakemake(
        snakefile,
        config=config,
        targets=config['targets'],
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


def path_resolve(x):
    return str(pathlib.Path(x).resolve())


def parse_commandline():
    # command line arguments
    parser = argparse.ArgumentParser(
        description=('Parameter optimization for Stacks'),
        formatter_class=argparse.RawTextHelpFormatter)
    parser.add_argument(
        '--dryrun',
        help='Do not execute anything.',
        action='store_true',
        dest='dryrun')
    parser.add_argument(
        '--individuals',
        help='Number of individuals per replicate (default 12).',
        type=int,
        dest='individuals',
        default=12) 
    parser.add_argument(
        '-m',
        help=('Optimised m from optim_Mm. Minimum number of identical,\n'
              'raw reads required to create a stack.'),
        type=str,
        dest='m',
        default=None)
    parser.add_argument(
        '-M',
        help=('Optimised M from optim_Mm. Number of mismatches allowed\n'
              'between loci when processing a single individual.'),
        type=str,
        dest='M',
        default=None)
    parser.add_argument(
        '--mode',
        help=('Which optimisation step to run (default setup).\n'
              + colour.BLUE + colour.BOLD + 'setup' + colour.END +
              ': count input reads, filter and subset samples.\n'
              + colour.BLUE + colour.BOLD + 'optim_Mm' + colour.END +
              ': optimise M and m with n == 1.\n'
              + colour.BLUE + colour.BOLD + 'optim_n' + colour.END +
              ': optimise n for chosen M and m.\n'
              + colour.BLUE + colour.BOLD + 'compare_defaults' + colour.END +
              ': compare optimised m, M and n to\n'
              '                  defaults.\n'
              'Overridden by `--targets`.'),
        choices=['setup', 'optim_Mm', 'optim_n', 'compare_defaults'],
        default='setup',
        dest='mode')
    parser.add_argument(
        '-n',
        help=('Optimised n from optim_n. Number of mismatches allowed\n'
              'between loci when building the catalog.'),
        type=str,
        dest='n',
        default=None)
    parser.add_argument(
        '-o',
        help='Output directory',
        type=str,
        dest='outdir',
        default='output')
    parser.add_argument(
        'popmap',
        help=('Path to a population map file.\n'
              'Format is "<name> TAB <pop>", one sample per line.'),
        type=str)
    parser.add_argument(
        '--replicates',
        help='Number of replicates to run (default 1).',
        type=int,
        dest='replicates',
        default=1) 
    parser.add_argument(
        'samples',
        help='path to the directory containing the samples reads files.',
        type=str)
    parser.add_argument(
        '--targets',
        help=('Targets, e.g. rule or file names (default None).\n'
              'Specify --targets once for each target.\n'
              'Overrides `--mode`.'),
        type=str,
        action='append',
        dest='targets',
        default=None)
    parser.add_argument(
        '--singularity_args',
        help=('Arguments for singularity (default "").\n'),
        type=str,
        dest='singularity_args',
        default='')
    default_threads = min(os.cpu_count() // 2, 50)
    parser.add_argument(
        '--threads',
        help=('Number of threads (default %i).' % default_threads),
        type=int,
        dest='threads',
        default=default_threads)
    args = vars(parser.parse_args())

    # check the arguments
    if args['mode'] and args['targets']:
        parser.error('Don\'t provide --mode and --targets')
    if args['mode'] == 'setup':
        args['targets'] = ['subset_samples']
    elif args['mode'] == 'optim_Mm':
        args['targets'] = ['optim_Mm']
    elif args['mode'] == 'optim_n':
        args['targets'] = ['optim_n']
        # check that M and m are provided if we're going to optimise n
        if not (args['m'] and args['M']):
            parser.error('Optimised m and M values are required to optimise n')
    elif args['mode'] == 'compare_defaults':
        args['targets'] = ['compare_defaults']
        # check that M and m are provided if we're going to optimise n
        if not (args['m'] and args['M'] and args['n']):
            parser.error(('Optimised m, M  and n values are required '
                          'to compare with the defaults'))

    # only return non-null args
    return {x: args[x] for x in args.keys() if args[x] is not None}

def main():
    args = parse_commandline()

    # set up outdir
    if not os.path.isdir(args['outdir']):
        os.makedirs(args['outdir'])

    # get full paths
    args['outdir'] = path_resolve(args['outdir'])
    args['samples'] = path_resolve(args['samples'])
    args['popmap'] = path_resolve(args['popmap'])

    # set up logging
    outdir = args['outdir']
    print(outdir)
    log_dir = os.path.join(outdir, 'logs')
    print(log_dir)
    args['log_dir'] = log_dir
    if not os.path.isdir(log_dir):
        os.makedirs(log_dir)

    # print the dag
    print_graph(snakefile, args, os.path.join(log_dir, "before"))

    # check if we have singularity
    use_singularity = True if shutil.which('singularity') else False

    # run the pipeline
    snakemake.snakemake(
        snakefile=snakefile,
        config=args,
        cores=args['threads'],
        targets=args['targets'],
        dryrun=args['dryrun'],
        lock=True,
        workdir=outdir,
        ignore_incomplete=True,
        use_singularity=use_singularity,
        singularity_args=args['singularity_args'])


###########
# GLOBALS #
###########

snakefile = resource_filename(__name__, 'Snakefile')

if __name__ == '__main__':
    main()
