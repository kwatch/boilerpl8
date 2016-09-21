# -*- coding: utf-8 -*-

import sys, os, re
import shutil
from glob import glob
import unittest

from oktest import ok, test, subject, situation, at_end, skip, todo
from oktest.dummy import dummy_io

import boilerpl8


class Boilerpl8_TC(unittest.TestCase):

    help_message = r"""
{script} -- download boilerplate files

Usage:
  {script} [options] github:<USER>/<REPO> <DIR>
  {script} [options] file:<PATH> <DIR>

Options:
  -h, --help       :  help
  -v, --version    :  version
  -B               :  not append '-boilerpl8' to github repo name

Examples:

  ## download boilerplate files from github
  $ {script} github:kwatch/hello-python mypkg1           # for python
  $ {script} github:kwatch/hello-ruby mygem1             # for ruby
  $ {script} github:kwatch/keight-python myapp1          # for keight.py

  ## '-B' option doesn't append '-boilerpl8' to github repo name
  $ {script} -B github:h5bp/html5-boilerplate website1   # for html5

  ## expand boilerplate files
  $ {script} file:./keight-python.tar.gz myapp1

"""[1:].format(script="boilerpl8")

    def provide_app(self):
        return boilerpl8.App("boilerpl8")


    @test("prints help message when '-h' or '--help' specified.")
    def _(self, app):
        expected = self.help_message
        #
        status = None
        with dummy_io() as d_io:
            status = app.run("-hv")
        sout, serr = d_io
        ok (sout)   == expected
        ok (status) == 0
        #
        status = None
        with dummy_io() as d_io:
            status = app.run("--help", "foo", "bar")
        sout, serr = d_io
        ok (sout)   == expected
        ok (status) == 0

    @test("prints version number when '-v' or '--version' specified.")
    def _(self, app):
        expected = "%s\n" % boilerpl8.__release__
        #
        status = None
        with dummy_io() as d_io:
            status = app.run("-v")
        sout, serr = d_io
        ok (sout)   == expected
        ok (status) == 0
        #
        status = None
        with dummy_io() as d_io:
            status = app.run("--version", "foo", "bar")
        sout, serr = d_io
        ok (sout)   == expected
        ok (status) == 0

    @test("downloads and expand github:kwatch/hello-ruby")
    def _(self, app):
        target_dir = "test-app1"
        @at_end
        def _():
            if os.path.exists(target_dir):
                shutil.rmtree(target_dir)
            for x in glob("hello-python_*.zip"):
                os.unlink(x)
        #
        status = app.run("github:kwatch/hello-ruby", target_dir)
        ok (target_dir).is_dir()
        ok ("%s/%s.gemspec" % (target_dir, target_dir)).is_file()
        ok ("%s/%s.gemspec" % (target_dir, "hello")).not_exist()
        ok ("%s/__init.rb"  % (target_dir, )).not_exist()
        ok (status) == 0

    @test("downloads and expand with '-B' option")
    def _(self, app):
        target_dir = "test-site1"
        @at_end
        def _():
            if os.path.exists(target_dir):
                shutil.rmtree(target_dir)
            for x in glob("html5-boilerplate_*.zip"):
                os.unlink(x)
        #
        status = app.run("-B", "github:h5bp/html5-boilerplate", target_dir)
        ok (target_dir).is_dir()
        ok (status) == 0



if __name__ == '__main__':
    import oktest
    oktest.main()
