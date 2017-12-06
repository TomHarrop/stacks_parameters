stacks_parameters
=================

Perform parameter optimisation following the recommendations in ``link to Parameter Space paper`` 

Requirements
------------

* ``python3`` 3.5 or newer with ``pip``
* ``R`` packages ``data.table`` and ``ggplot2``
* ``statswrapper.sh`` from the BBmap_ package

.. _BBmap: http://jgi.doe.gov/data-and-tools/bbtools/bb-tools-user-guide/bbmap-guide/ 

Installation
------------

``pip3 install git+git://github.com/tomharrop/stacks_parameters.git``

Usage
-----

.. code::

usage: stacks_parameters [-h] [--dryrun] [--individuals INDIVIDUALS] [-m M]
                         [-M M]
                         [--mode {setup,optim_Mm,optim_n,compare_defaults}]
                         [-n N] [-o OUTDIR] [--replicates REPLICATES]
                         [--targets TARGETS] [--threads THREADS]
                         popmap samples

Parameter optimization for Stacks

positional arguments:
  popmap                Path to a population map file.
                        Format is "<name> TAB <pop>", one sample per line
  samples               path to the directory containing the samples reads files

optional arguments:
  -h, --help            show this help message and exit
  --dryrun              Do not execute anything
  --individuals INDIVIDUALS
                        Number of individuals per replicate (default 12)
  -m M                  Optimised m from optim_Mm. Minimum number of identical,
                        raw reads required to create a stack.
  -M M                  Optimised M from optim_Mm. Number of mismatches allowed
                        between loci when processing a single individual.
  --mode {setup,optim_Mm,optim_n,compare_defaults}
                        Which optimisation step to run (default setup).
                        setup: count input reads, filter and subset samples.
                        optim_Mm: optimise M and m with n == 1.
                        optim_n: optimise n for chosen M and m.
                        compare_defaults: compare optimised m, M and n to defaults.
                        Overridden by `--targets`
  -n N                  Optimised n from optim_n. Number of mismatches allowed
                        between loci when building the catalog.
  -o OUTDIR             Output directory
  --replicates REPLICATES
                        Number of replicates to run (default 1).
  --targets TARGETS     Targets, e.g. rule or file names (default None).
                        Specify --targets once for each target.
                        Overrides `--mode`
  --threads THREADS     Number of threads
  