# -*- coding: utf-8 -*-

from setuptools import setup

release = '$Release: 0.0.0 $'.split()[1]

description = r"""
Boilerpl8.py is a scaffolding tool. It downloads boilerplate files
from github repository, and expand it into local disk.

Examples::

    ## create Python project
    $ boilerpl8 github:kwatch/hello-python myproj1

    ## create Keight.py project
    $ boilerpl8 github:kwatch/keight-python myapp1

    ## create webiste based on html5-boilerplate
    $ boilerpl8 -B github:h5bp/html5-boilerplate

See https://github.com/kwatch/boilerpl8/tree/python for details.

(Boilerpl8.poy requires Python 2.7, 3.3 or later.)
"""[1:]


setup(
    name             = 'boilerpl8',
    version          = release,
    description      = "Scaffodling tool to download and expand boilerplate files",
    long_description = description,
    keywords         = 'scaffold',
    author           = 'makoto kuwata',
    author_email     = 'kwa(at)kuwata-lab.com',
    url              = 'https://github.com/kwatch/boilerpl8/tree/python',
    license          = 'MIT License',
    #platform         = 'any',
    py_modules       = ['boilerpl8'],
    scripts          = ['bin/boilerpl8'],
    #zip_safe         = False,
    install_requires = [],
    extras_require   = {},
    tests_require    = ["oktest", "kook"],
    classifiers      = [
        'Development Status :: 4 - Beta',
        'Environment :: Console',
        'Intended Audience :: Developers',
        'License :: OSI Approved :: MIT License',
        'Programming Language :: Python',
        'Programming Language :: Python :: 2.7',
        'Programming Language :: Python :: 3',
        'Programming Language :: Python :: 3.3',
        'Programming Language :: Python :: 3.4',
        'Programming Language :: Python :: 3.5',
        'Topic :: Software Development :: Code Generators',
    ],
)
