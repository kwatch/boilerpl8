# -*- coding: utf-8 -*-

###
### $Release: 0.2.0 $
### $Copyright: copyright(c) 2016 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

require 'open-uri'
require 'json'
require 'fileutils'


module Boilerpl8


  RELEASE = '$Release: 0.2.0 $'.split()[1]


  module ShellHelper
    PROMPT = "[boilerpl8]$"

    def _prompt()
      return PROMPT
    end

    def rm_rf(path)
      puts "#{_prompt()} rm -rf #{path}"
      FileUtils.rm_rf path
    end

    def mv(oldpath, newpath)
      puts "#{_prompt()} mv #{oldpath} #{newpath}"
      File.rename oldpath, newpath
    end

    def sys(command)
      puts "#{_prompt()} #{command}"
      system command
    end

    def chdir(dir, &block)
      puts "#{_prompt()} cd #{dir}"
      Dir.chdir(dir, &block)
      puts "#{_prompt()} cd -"
    end

  end


  INITIALIZER_SCRIPTS = [
    ["__init.rb"   , "ruby"  ],
    ["__init.py"   , "python"],
    ["__init.js"   , "node"  ],
    ["__init.pl"   , "perl"  ],
    ["__init.php"  , "php"   ],
    ["__init.lua"  , "lua"   ],
    ["__init.exs"  , "elixir"],
    ["__init.sh"   , "bash"  ],
  ]


  class Operation
    include ShellHelper

    def do_everything(boilerplate_name, target_dir, options)
      url, filename = resolve(boilerplate_name, options)
      filepath = download(url, filename)
      basedir = extract(filepath, target_dir)
      ok = kick_initializer(basedir)
      return ok    # true or false
    end

    protected

    def resolve(arg, options)
      raise NotImplementedError.new("#{self.class.name}#resolve(): not implemented yet.")
    end

    def download(url, filename)
      print "Download from #{url} ..."
      content = open(url) {|f| f.read }
      puts " done."
      File.open(filename, 'wb') {|f| f.write(content) }
      return filename
    end

    def extract(filename, basedir)
      filename =~ /\.(zip|tgz|tar\.(gz|bz2|xz))\z/  or
        err("#{filename}: expected '*.zip' or '*.tar.gz'")
      base = File.basename($`)
      basedir ||= base
      rm_rf basedir if File.exist?(basedir)
      #
      case filename
      when /\.zip\z/
        tmpdir = basedir + ".tmp"
        sys "unzip -q -d #{tmpdir} #{filename}"
        paths = Dir.glob("#{tmpdir}/*")
        if paths.length == 1 && File.directory?(paths[0])
          mv paths[0], basedir
          rm_rf tmpdir
        else
          mv tmpdir, basedir
        end
      else
        sys "tar xf #{filename}"
        mv base, basedir if base != basedir
      end
      #
      return basedir
    end

    def kick_initializer(basedir)
      chdir(basedir) do
        INITIALIZER_SCRIPTS.each do |script, lang|
          return sys "#{lang} #{script}" if File.exist?(script)
        end
      end
      return true   # initializer script not exist
    end

    def err(msg)
      raise CommandOptionError.new(msg)
    end

    def self.err(msg)
      raise CommandOptionError.new(msg)
    end

    public

    ALL = []

    def self.inherited(klass)
      ALL << klass
    end

    def self.create(boilerplate_name)
      #; [!xr4c6] reports error when argument has no schema.
      boilerplate_name =~ /\A(\w+:)/  or
        err("#{boilerplate_name}: expected 'github:' or 'file:' schema.")
      schema = $1
      #; [!95h3f] reports error when argument has unknown schema.
      klass = ALL.find {|cls| cls.const_get(:SCHEMA) == schema }  or
        err("#{boilerplate_name}: unknown schema (expected 'github:' or 'file:').")
      return klass.new()
    end

  end


  class FileSystemOp < Operation

    SCHEMA = "file:"

    protected

    def resolve(arg, options)
      arg =~ %r'\Afile:(.+)'  or err("#{arg}: unexpected format.")
      filepath = $1
      return filepath, File.basename(filepath)
    end

    def download(filepath, filename)
      return filepath
    end

  end


  class GithubOp < Operation

    SCHEMA = "github:"

    protected

    def resolve(arg, options)
      arg =~ %r'\Agithub:([^/]+)/([^/]+)\z'  or err("#{arg}: unexpected format.")
      user, repo = $1, $2
      #
      suffix = options['B'] ? "" : "-boilerpl8"
      api_url = "https://api.github.com/repos/#{user}/#{repo}#{suffix}/releases"
      begin
        json_str = open(api_url) {|f| f.read }
      rescue OpenURI::HTTPError => ex
        hint = options['B'] \
             ? "confirm repository name, or try without '-B' option." \
             : "confirm repository name, or maybe you missed '-B' option."
        err("#{arg}: repository not found\n  (api: GET #{api_url})\n  (Hint: #{hint})")
      end
      #
      json_arr = JSON.parse(json_str)
      dict = json_arr[0]
      asset = (dict["assets"] || [])[0]
      if asset
        zip_url = asset["browser_download_url"]
        filename = zip_url ? File.basename(zip_url) : nil
      else
        zip_url = dict["zipball_url"]
        filename = "#{repo}_#{dict['tag_name']}.zip"
      end
      zip_url  or
        err("ERROR: can't find zip file under github.com/#{user}/#{repo}/releases")
      return zip_url, filename
    end

  end


  class MainApp

    COMMAND_OPTIONS = [
      "-h, --help       :  help",
      "-v, --version    :  version",
      "-B               :  not append '-boilerpl8' to github repo name",
    ]

    def self.main
      begin
        status = self.new.run(*ARGV)
        exit status
      rescue CommandOptionError => ex
        $stderr.puts ex.message
        exit 1
      end
    end

    def initialize(script_name=nil)
      @script_name = script_name || File.basename($0)
    end

    def run(*args)
      parser = CommandOptionParser.new(COMMAND_OPTIONS)
      options = parser.parse(args)
      #
      if options['help']
        puts help_message()
        return 0
      end
      #
      if options['version']
        puts RELEASE
        return 0
      end
      #
      boilerplate_name = args[0]  # ex: "github:kwatch/hello-ruby"
      target_dir       = args[1]  # ex: "mygem1"
      #; [!eqisx] reports error when boilerplate name or target dir is not specified.
      boilerplate_name  or raise err("#{@script_name}: argument required.")
      target_dir        or raise err("#{@script_name}: target directory name required.")
      #
      op = Operation.create(boilerplate_name)
      ok = op.do_everything(boilerplate_name, target_dir, options)
      return ok ? 0 : 1
    end

    def help_message
      script = @script_name
      buf = <<"END"
#{script} -- download boilerplate files

Usage:
  #{script} [options] github:<USER>/<REPO> <DIR>
  #{script} [options] file:<PATH> <DIR>

Options:
END
      COMMAND_OPTIONS.each {|s| buf << "  #{s}\n" }
      buf << <<"END"

Examples:

  ## download boilerplate files from github
  $ #{script} github:kwatch/hello-ruby mygem1             # for ruby
  $ #{script} github:kwatch/hello-python mypkg1           # for python
  $ #{script} github:kwatch/keight-ruby myapp1            # for keight.rb

  ## '-B' option doesn't append '-boilerpl8' to github repo name
  $ #{script} -B github:h5bp/html5-boilerplate website1   # for html5

  ## expand boilerplate files
  $ #{script} file:./keight-ruby.tar.gz myapp1

END
    end

    private

    def err(msg)
      raise CommandOptionError.new(msg)
    end

  end


  class CommandOptionError < StandardError
  end


  CommandOptionDefinition = Struct.new(:short, :long, :param, :desc)


  class CommandOptionParser

    def initialize(optdef_strs)
      @optdef_strs = optdef_strs
      @optdefs = []
      optdef_strs.each do |optdef_str|
        case optdef_str
        when /-(\w), --(\w[-\w]*)(?:=(\S+))?\s*:\s*(\S.*)?/ ; t = [$1, $2, $3, $4]
        when /-(\w)(?:\s+(\S+))?\s*:\s*(\S.*)?/             ; t = [$1, nil, $2, $3]
        when /--(\w[-\w]*)(?:=(\S+))?\s*:\s*(\S.*)?/        ; t = [nil, $1, $2, $3]
        else
          raise "unexpected option definition: #{optdef_str}"
        end
        short, long, param, desc = t
        @optdefs << CommandOptionDefinition.new(short, long, param, desc)
      end
    end

    attr_reader :optdefs

    def parse(args)
      options = {}
      while ! args.empty? && args[0].start_with?('-')
        argstr = args.shift
        if argstr.start_with?('--')
          rexp = /\A--([-\w]+)(?:=(.*))?\z/
          argstr =~ rexp                   or err("#{argstr}: invalid option format.")
          name, value = $1, $2
          optdef = find_by(:long, name)    or err("--#{name}: unknown option.")
          optdef.param.nil? || value       or err("#{argstr}: argument required.")
          optdef.param      || value.nil?  or err("#{argstr}: unexpected argument.")
          options[optdef.long] = value || true
        else
          n = argstr.length
          i = 0
          while (i += 1) < n
            ch = argstr[i]
            optdef = find_by(:short, ch)   or err("-#{ch}: unknown option.")
            if optdef.param.nil?   # no arguments
              options[optdef.long || optdef.short] = true
            else                   # argument required
              param = argstr[(i+1)..-1]
              param = args.shift if param.empty?
              param  or err("-#{ch}: argument required.")
              options[optdef.long || optdef.short] = param
              break
            end
          end
        end
      end
      return options
    end

    private

    def find_by(key, value)
      return @optdefs.find {|x| x.__send__(key) == value }
    end

    def err(msg)
      raise CommandOptionError.new(msg)
    end

  end


end


if __FILE__ == $0
  Boilerpl8::MainApp.main()
end
