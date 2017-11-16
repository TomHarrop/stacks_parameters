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
    version='0.0.1',
    description='Parameter optimization for Stacks',
    long_description=readme(),
    url='https://github.com/TomHarrop/stacks_parameters',
    author='Tom Harrop',
    author_email='twharrop@gmail.com',
    license='GPL-3',
    packages=find_packages(),
    install_requires=[
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
        'stacks_parameters/src/util/stacks_catalog_to_fasta.py'
    ],
    zip_safe=False)
