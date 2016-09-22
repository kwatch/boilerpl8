# -*- coding: utf-8 -*-

###
### $Release: 0.0.0 $
### $Copyright: copyright(c) 2016 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

import sys, os, re
PY2 = sys.version_info[0] == 2
PY3 = sys.version_info[0] == 3
assert PY2 or PY3

import json
import shutil
from glob import glob
from contextlib import contextmanager
if PY2:
    from urllib2 import urlopen
elif PY3:
    from urllib.request import urlopen


__release__ = '$Release: 0.0.0 $'.split()[1]


def rm_rf(path):
    print("$ rm -rf %s" % path)
    shutil.rmtree(path)

def mv(oldpath, newpath):
    print("$ mv %s %s" % (oldpath, newpath))
    os.rename(oldpath, newpath)

def system(command):
    print("$ %s" % command)
    os.system(command)

@contextmanager
def chdir(dir):
    pwd = os.getcwd()
    print("$ %s" % dir)
    os.chdir(dir)
    try:
        yield
    finally:
        print("$ cd -")
        os.chdir(pwd)


class Operation(object):

    def resolve(self, arg, options):
        raise NotImplementedError("%s.resolve(): not implemented yet." % self.__class__.__name__)

    def download(self, url, filename):
        sys.stdout.write("Download from %s ..." % url)
        resp = urlopen(url)
        content = resp.read()
        sys.stdout.write(" done.\n")
        with open(filename, 'wb') as f:
            f.write(content)
        return filename

    def extract(self, filename, basedir):
        m = re.search(r'\.(zip|tgz|tar\.(gz|bz2|xz))$', filename)
        if not m:
            raise _err("%s: expected '*.zip' or '*.tar.gz'" % filename)
        base = filename[:m.start(0)]
        basedir = basedir or base
        if os.path.exists(basedir):
            rm_rf(basedir)
        #
        if filename.endswith('.zip'):
            tmpdir = basedir + ".tmp"
            system("unzip -q -d %s %s" % (tmpdir, filename))
            paths = glob("%s/*" % tmpdir)
            if len(paths) == 1 and os.path.isdir(paths[0]):
                mv(paths[0], basedir)
                rm_rf(tmpdir)
            else:
                mv(tmpdir, basedir)
        else:
            system("tar xf %s" % filename)
            if base != basedir:
                mv(base, basedir)
        #
        return basedir

    def kick_initializer(self, basedir):
        with chdir(basedir):
            for script, lang in INITIALIZER_SCRIPTS:
                if os.path.isfile(script):
                    system(" %s %s" % (lang, script))
                break

    @classmethod
    def create(cls, *args):
        m = re.match(r'^(\w+:)', args[0])
        if not m:
            raise _err("%s: expected 'github:' or 'file:' schema." % args[0])
        schema = m.group(1)
        for klass in Operation.__subclasses__():
            if klass.SCHEMA == schema:
                break
        else:
            raise _err("%s: unknown schema." % args[0])
        return klass()


class FileSystemOperation(Operation):

    SCHEMA = "file:"

    def resolve(self, arg, options):
        m = re.match(r'^file:(.+)', arg)
        if not m:
            raise _err("%s: unexpected format." % arg)
        filepath = m.group(1)
        return filepath, os.path.basename(filepath)

    def download(self, filepath, filename):
        return filepath


class GithubOperation(Operation):

    SCHEMA = "github:"

    def resolve(self, arg, options):
        m = re.match(r'^github:([^/]+)/([^/]+)$', arg)
        if not m:
            raise _err("%s: unexpected format." % arg)
        user, repo = m.groups()
        #
        suffix = ("" if options.get('B') else "-boilerpl8")
        api_url = "https://api.github.com/repos/%s/%s%s/releases" % (user, repo, suffix)
        try:
            resp = urlopen(api_url)
            json_str = resp.read()
        except Exception as ex:
            if options.get('B'):
                hint = "confirm repository name, or try without '-B' option."
            else:
                hint = "confirm repository name, or maybe you missed '-B' option."
            raise _err("%s: repository not found.\n" % repo +
                       "  (api: GET %s)\n" % api_url +
                       "  (Hint: %s)" % hint)
        #
        if isinstance(json_str, bytes):
            json_str = json_str.decode('utf-8')
        json_arr = json.loads(json_str)
        d = json_arr[0]
        asset = (d["assets"][0] if d["assets"] else None)
        if asset:
            zip_url = asset["browser_download_url"]
            filename = (os.path.basename(zip_url) if zip_url else None)
        else:
            zip_url = d["zipball_url"]
            filename = "%s_%s.zip" % (repo, d['tag_name'])
        if not zip_url:
            raise _err("ERROR: can't find zip file under github.com/%s/%s/releases" % (user, repo))
        return zip_url, filename


INITIALIZER_SCRIPTS = [
    ("__init.rb"   , "ruby"  ),
    ("__init.py"   , "python"),
    ("__init.js"   , "node"  ),
    ("__init.pl"   , "perl"  ),
    ("__init.php"  , "php"   ),
    ("__init.lua"  , "lua"   ),
    ("__init.exs"  , "elixir"),
    ("__init.sh"   , "bash"  ),
]


class App(object):

    COMMAND_OPTIONS = [
        "-h, --help       :  help",
        "-v, --version    :  version",
        "-B               :  not append '-boilerpl8' to github repo name",
    ]

    def __init__(self, script_name):
        self.script_name = script_name

    def run(self, *args):
        args = list(args)
        parser = CommandOptionParser(self.COMMAND_OPTIONS)
        options = parser.parse(args)
        #
        if options.get('help'):
            print(self.help_message())
            return 0
        #
        if options.get('version'):
            print(__release__)
            return 0
        #
        if not args:
            raise _err("%s: argument required." % self.script_name)
        op = Operation.create(*args)
        url, filename = op.resolve(args[0], options)
        filepath = op.download(url, filename)
        basedir = op.extract(filepath, (args[1] if len(args) >= 2 else None))
        op.kick_initializer(basedir)
        return 0

    def help_message(self):
        buf = []; add = buf.append
        add(r"""
{script} -- download boilerplate files

Usage:
  {script} [options] github:<USER>/<REPO> <DIR>
  {script} [options] file:<PATH> <DIR>

Options:
"""[1:])
        for s in self.COMMAND_OPTIONS:
            add("  %s\n" % s)
        add(r"""
Examples:

  ## download boilerplate files from github
  $ {script} github:kwatch/hello-python mypkg1           # for python
  $ {script} github:kwatch/hello-ruby mygem1             # for ruby
  $ {script} github:kwatch/keight-python myapp1          # for keight.py

  ## '-B' option doesn't append '-boilerpl8' to github repo name
  $ {script} -B github:h5bp/html5-boilerplate website1   # for html5

  ## expand boilerplate files
  $ {script} file:./keight-python.tar.gz myapp1
""")
        return "".join(buf).format(script=self.script_name)



class CommandOptionError(Exception):
    pass


def _err(msg):
    raise CommandOptionError(msg)



class CommandOptionDefinition(object):

    def __init__(self, short, long, param, desc):
        self.short = short
        self.long  = long
        self.param = param
        self.desc  = desc


class CommandOptionParser(object):

    def __init__(self, optdef_strs):
        def fn(s):
            short = long = param = desc = None
            m = re.match(r'^-(\w), --(\w[-\w]*)(?:=(\S+))?\s*:\s*(\S.*)?$', s)
            if m:
                short, long, param, desc = m.groups()
                return short, long, param, desc
            m = re.match(r'^-(\w)(?:\s+(\S+))?\s*:\s*(\S.*)?$', s)
            if m:
                short, params, desc = m.groups()
                return short, long, param, desc
            m = re.match(r'^--(\w[-\w]*)(?:=(\S+))?\s*:\s*(\S.*)?$', s)
            if m:
                long, params, desc = m.groups()
                return short, long, param, desc
            return None
        #
        self.optdef_strs = optdef_strs
        self.optdefs = []
        for optdef_str in optdef_strs:
            t = fn(optdef_str.strip())
            if t is None:
                raise TypeError("unexpected option definition: %s" % optdef_str)
            short, long, param, desc = t
            self.optdefs.append(CommandOptionDefinition(short, long, param, desc))

    def parse(self, args):
        assert isinstance(args, list)
        options = {}
        while args and args[0].startswith('-'):
            argstr = args.pop(0)
            if argstr.startswith('--'):
                m = re.match(r'^--([-\w]+)(?:=(.*))?$', argstr)
                if not m:
                    raise _err("%s: invalid option format.")
                name, value = m.groups()
                optdef = self._find_by('long', name)
                if optdef is None:
                    raise _err("--%s: unknown option." % name)
                if optdef.param is not None and value is None:
                    raise _err("%s: argument required." % argstr)
                if optdef.param is None and value is not None:
                    raise _err("%s: unexpected argument." % argstr)
                options[optdef.long] = (True if value is None else vlue)
            else:
                n = len(argstr)
                i = 1
                while i < n:
                    ch = argstr[i]
                    optdef = self._find_by('short', ch)
                    if optdef is None:
                        raise _err("-%s: unknown option." % ch)
                    if optdef.param is None:   # no arguments
                        options[optdef.long or optdef.short] = True
                        i += 1
                    else:                      # argument required
                        param = argstr[(i+1):]
                        if not param:
                            if args:
                                param = args.pop(0)
                            else:
                                raise _err("-%s: argument required." % ch)
                        options[optdef.long or optdef.short] = param
                        break
        return options

    def _find_by(self, key, value):
        for x in self.optdefs:
            if getattr(x, key, None) == value:
                return x
        return None


def main():
    script_name = os.path.basename(sys.argv[0])
    args = sys.argv[1:]
    try:
        status = App(script_name).run(*args)
    except CommandOptionError as ex:
        sys.stderr.write("%s\n" % (ex,))
        status = 1
    sys.exit(status)


if __name__ == '__main__':
    main()
