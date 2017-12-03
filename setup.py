#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from setuptools import setup
from setuptools import find_packages


# load README.rst
def readme():
    with open('README.rst') as file:
        return file.read()


setup(
    name='stacks_parameters',
    version='0.0.5',
    description='Parameter optimization for Stacks',
    long_description=readme(),
    url='https://github.com/TomHarrop/stacks_parameters',
    author='Tom Harrop',
    author_email='twharrop@gmail.com',
    license='GPL-3',
    packages=find_packages(),
    install_requires=[
        'pandas>=0.21.0',
        'numpy>=1.13.3',
        'snakemake>=4.0.0'
    ],
    entry_points={
        'console_scripts': [
            'stacks_parameters = stacks_parameters.__main__:main'
            ],
    },
    package_data={
        'basecall_wrapper': [
            'Snakefile'
        ],
        '': ['README.rst']
    },
    scripts=[
        'stacks_parameters/src/util/stacks_catalog_to_fasta.py',
        'stacks_parameters/src/filter_populations_map.R',
        'stacks_parameters/src/parse_denovo_map_logs.py',
        'stacks_parameters/src/parse_stacks_output.R',
        'stacks_parameters/src/combine_stacks_data.R',
        'stacks_parameters/src/plot_coverage.R',
        'stacks_parameters/src/plot_stacks_output.R'],
    zip_safe=False)
