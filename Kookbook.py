# -*- coding: utf-8 -*-

import sys, os, re
from glob import glob

kookbook.default = 'howto'

package   = prop('package', 'boilerpl8')
release   = prop('release', '$Release: 0.0.0 $'.split()[1])
copyright = prop('copyright', "copyright(c) 2016 kuwata-lab.com all rights reserved")
license   = "MIT License"
basename  = "%s-%s" % (package, release)
python    = prop('python', sys.executable)
vs_home   = prop('vs_home', "/opt/vs")

python_versions = (
    #'2.5.5',
    '2.6.9',
    '2.7.7',
    #'3.0.1',
    #'3.1.5',
    #'3.2.6',
    '3.3.6',
    '3.4.1',
    '3.5.1',
)

howto_release = r"""
  $ git diff          # confirm that no diff
  $ kk test
  $ kk --release={release} edit
  $ git diff
  $ kk package
  $ tar tf dist/{package}-{release}.tar.gz
  $ kk publish
  $ git checkout .    # reset release number
  $ git tag python-{release}
  $ git push --tags
"""[1:].format(release=release, package=package)


@recipe
def task_howto(c):
    """show how to release"""
    print("How to release:")
    print("")
    print(howto_release)


@recipe
@spices("-a: run test on Python 2.x and 3.x")
def task_test(c, *args, **kwargs):
    """do test"""
    if 'a' in kwargs:
        for pyver in python_versions:
            pybin = "%s/python/%s/bin/python" % (vs_home, pyver)
            print(c%"------- Python $(pyver) -----------")
            system_f(c%"$(pybin) -m oktest tests -sp ")
    else:
        system(c%"python -m oktest tests -sp")


@recipe
def task_manifest(c):
    """update MANIFEST file"""
    s = ("from distutils.core import setup\n"
         "setup(name='x', version='x', url='x', author='x', author_email='x')\n")
    with open("_manifest.py", 'w') as f:
        f.write(s)
    try:
        system(c%'$(python) _manifest.py -q sdist --force-manifest --manifest-only')
    finally:
        rm("_manifest.py")
    system("sed -i.bak -e '/_manifest.py/d' MANIFEST")
    rm("MANIFEST.bak")


@recipe
@ingreds("manifest")
def task_edit(c, *args):
    """repleace such as '\x24Release\x24' in files"""
    replacer = [
        (r'\$(Package)\$',   package),
        (r'\$(Release)\$',   release),
        (r'\$(Copyright)\$', copyright),
        (r'\$(License)\$',   license),
        (r'\$(Package):.*?\$',    r'$\1: %s $' % package),
        (r'\$(Release):.*?\$',    r'$\1: %s $' % release),
        (r'\$(Copyright):.*?\$',  r'$\1: %s $' % copyright),
        (r'\$(License):.*?\$',    r'$\1: %s $' % license),
    ]
    with open("MANIFEST") as f:
        filepaths = [ line.strip() for line in f if line[0] != '#' ]
    edit(filepaths, by=replacer)


@recipe
@ingreds('manifest')
def task_package(c):
    """create packages"""
    #rm_rf("dist/*")
    system(c%'$(python) setup.py -q sdist')


@recipe
@ingreds('package')
def task_publish(c):
    """upload new version to pypi"""
    sys.stdout.write("** Are you sure to upload %s-%s.tar.gz? [y/N]: " % (package, release))
    answer = sys.stdin.readline().strip()
    if answer.startswith(('y', 'Y')):
        #rm_rf("dist/*")
        system(c%'$(python) setup.py register')
        system(c%'$(python) setup.py sdist upload')


kookbook.load('@kook/books/clean.py')
CLEAN.extend(('**/*.pyc', '**/__pycache__', '*.egg-info',
              '%s.zip' % package, 'MANIFEST'))
