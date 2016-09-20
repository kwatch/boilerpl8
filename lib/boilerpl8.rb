# -*- coding: utf-8 -*-

###
### $Release: 0.0.0 $
### $Copyright: copyright(c) 2016 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

require 'open-uri'
require 'json'
require 'fileutils'


###
###
###
module Boilerpl8


  RELEASE = '$Release: 0.0.0 $'.split()[1]


  class Operation

    def resolve(arg)
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
      if File.exist?(basedir)
        puts "$ rm -rf #{basedir}"
        FileUtils.rm_rf(basedir)
      end
      #
      case filename
      when /\.zip\z/
        puts "$ unzip -q -d #{basedir}.tmp #{filename}"
        system "unzip -q -d #{basedir}.tmp #{filename}"
        paths = Dir.glob("#{basedir}.tmp/*")
        if paths.length == 1 && File.directory?(paths[0])
          puts "$ mv #{paths[0]} #{basedir}"
          File.rename paths[0], basedir
          puts "$ rm -rf #{basedir}.tmp"
          FileUtils.rm_rf "#{basedir}.tmp"
        else
          puts "$ mv #{basedir}.tmp #{basedir}"
          File.rename "#{basedir}.tmp", basedir
        end
      else
        puts "$ tar xf #{filename}"
        system "tar xf #{filename}"
        if base != basedir
          puts "$ mv #{base} #{basedir}"
          File.rename base, basedir
        end
      end
      return basedir
    end

    def kick_initializer(basedir)
      puts "$ cd #{basedir}"
      Dir.chdir(basedir) do
        INITIALIZER_SCRIPTS.each do |script, lang|
          if File.exist?(script)
            puts "$ #{lang} #{script}"
            system "#{lang} #{script}"
            break
          end
        end
      end
      puts "$ cd -"
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

    def err(msg)
      raise CommandOptionError.new(msg)
    end

    def self.err(msg)
      raise CommandOptionError.new(msg)
    end

    ALL = {}

    def self.create(*args)
      args[0] =~ /\A(\w+:)/  or err("#{args[0]}: expected 'github:' or 'file:' schema.")
      schema = $1
      klass = ALL[schema]    or err("#{args[0]}: unknown schema.")
      return klass.new()
    end

  end


  class FileSystemOperation < Operation

    SCHEMA = "file:"

    def resolve(arg)
      arg =~ %r'\Afile:(.+)'  or err("#{arg}: unexpected format.")
      filepath = $1
      return filepath, File.basename(filepath)
    end

    def download(filepath, filename)
      return filepath
    end

  end


  class GithubOperation < Operation

    SCHEMA = "github:"

    def resolve(arg)
      arg =~ %r'\Agithub:([^/]+)/([^/]+)\z'  or err("#{arg}: unexpected format.")
      user, repo = $1, $2
      #
      api_url = "https://api.github.com/repos/%s/%s/releases"
      if repo.end_with?('-boilerpl8')
        json_str = open(api_url % [user, repo]) {|f| f.read }
      else
        begin
          json_str = open(api_url % [user, repo+"-boilerpl8"]) {|f| f.read }
        rescue
          json_str = open(api_url % [user, repo]) {|f| f.read }
        end
      end
      #
      json_arr = JSON.parse(json_str)
      dict = json_arr[0]
      asset = dict["assets"][0]
      if asset
        zip_url = asset["browser_download_url"]
        filename = File.basename(zip_url) if zip_url
      else
        zip_url = dict["zipball_url"]
        filename = "#{repo}_#{dict['tag_name']}.zip"
      end
      zip_url  or
        err("ERROR: can't find zip file under github.com/#{user}/#{repo}/releases")
      return zip_url, filename
    end

  end


  Operation::ALL[FileSystemOperation::SCHEMA] = FileSystemOperation
  Operation::ALL[GithubOperation::SCHEMA    ] = GithubOperation


  class App

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
      ! args.empty?  or err("#{script_name()}: argument required.")
      op = Operation.create(*args)
      url, filename = op.resolve(args[0])
      filepath = op.download(url, filename)
      basedir = op.extract(filepath, args[1])
      op.kick_initializer(basedir)
    end

    def script_name
      return File.basename($0)
    end

    def help_message
      script = script_name()
      buf = <<"END"
#{script} -- download boilerplate files

Usage:
  #{script} [options] github:<USER>/<PROJECT> <DIR>
  #{script} [options] file:<PATH> <DIR>

Options:
END
      COMMAND_OPTIONS.each do |s|
        buf << "  #{s}\n"
      end
      buf << <<"END"

Examples:

  ## download boilerplate files from github
  $ #{script} github:h5bp/html5-boilerplate website1    # for html5
  $ #{script} github:h5bp/hello-ruby mygem1             # for ruby
  $ #{script} github:h5bp/hello-python mypkg1           # for python
  $ #{script} github:kwatch/keight-ruby myapp1          # for keight.rb

  ## expand boilerplate files
  $ #{script} file:./keight-ruby.tar.gz myapp1

END
    end

    private

    COMMAND_OPTIONS = [
      "-h, --help       :  help",
      "-v, --version    :  version",
    ]

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
        optdef_str =~ /-(\w), --(\w+)(?:=(\S+))?\s*:\s*(\S.*)?/  or
          raise "unexpected option definition: #{optdef_str}"
        short, long, param, desc = $1, $2, $3, $4
        @optdefs << CommandOptionDefinition.new(short, long, param, desc)
      end
    end

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


  class Main

    def self.main
      begin
        App.new.run(*ARGV)
        exit 0
      rescue CommandOptionError => ex
        $stderr.puts ex.message
        exit 1
      end
    end

  end


end


if __FILE__ == $0
  Boilerpl8::Main.main()
end
