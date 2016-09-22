# -*- coding: utf-8 -*-

require 'minitest/spec'
require 'minitest/autorun'
require 'minitest/ok'

require 'fileutils'

require_relative '../lib/boilerpl8'


describe Boilerpl8::App do

  help_message = <<END
#{File.basename(__FILE__)} -- download boilerplate files

Usage:
  boilerpl8_test.rb [options] github:<USER>/<PROJECT> <DIR>
  boilerpl8_test.rb [options] file:<PATH> <DIR>

Options:
  -h, --help       :  help
  -v, --version    :  version
  -B               :  not append '-boilerpl8' to github repo name

Examples:

  ## download boilerplate files from github
  $ boilerpl8_test.rb github:kwatch/hello-ruby mygem1             # for ruby
  $ boilerpl8_test.rb github:kwatch/hello-python mypkg1           # for python
  $ boilerpl8_test.rb github:kwatch/keight-ruby myapp1            # for keight.rb

  ## '-B' option doesn't append '-boilerpl8' to github repo name
  $ boilerpl8_test.rb -B github:h5bp/html5-boilerplate website1   # for html5

  ## expand boilerplate files
  $ boilerpl8_test.rb file:./keight-ruby.tar.gz myapp1

END

  describe '#run()' do

    it "prints help message when '-h' or '--help' specified." do
      expected = help_message
      #
      status = nil
      pr = proc { status = Boilerpl8::App.new.run("-hv") }
      ok {pr}.output?(expected)
      ok {status} == 0
      #
      status = nil
      pr = proc { status = Boilerpl8::App.new.run("--help", "foo", "bar") }
      ok {pr}.output?(expected)
      ok {status} == 0
    end

    it "prints version number when '-v' or '--version' specified." do
      expected = "#{Boilerpl8::RELEASE}\n"
      #
      status = nil
      pr = proc { status = Boilerpl8::App.new.run("-v") }
      ok {pr}.output?(expected)
      ok {status} == 0
      #
      status = nil
      pr = proc { status = Boilerpl8::App.new.run("--version", "foo", "bar") }
      ok {pr}.output?(expected)
      ok {status} == 0
    end

    it "downloads and expand github:kwatch/hello-ruby" do
      target_dir = "test-app1"
      begin
        status = Boilerpl8::App.new.run("github:kwatch/hello-ruby", target_dir)
        ok {target_dir}.dir_exist?
        ok {"#{target_dir}/#{target_dir}.gemspec"}.file_exist?
        ok {"#{target_dir}/hello.gemspec"}.NOT.file_exist?
        ok {"#{target_dir}/__init.rb"}.NOT.file_exist?
        ok {status} == 0
      ensure
        FileUtils.rm_rf target_dir
        FileUtils.rm_rf Dir.glob("hello-ruby_*.zip")
      end
    end

    it "downloads and expand with '-B' option" do
      target_dir = "test-site1"
      begin
        status = Boilerpl8::App.new.run("-B", "github:h5bp/html5-boilerplate", target_dir)
        ok {target_dir}.dir_exist?
        ok {status} == 0
      ensure
        FileUtils.rm_rf target_dir
        FileUtils.rm_rf Dir.glob("html5-boilerplate_*.zip")
      end
    end

  end


end
