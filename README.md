============
Boilerpl8.rb
============

($Release: 0.3.0 $)


Abount
------

Boilerpl8.rb is a scaffolding tool to download and expand boilerplate files.


Install
-------

```console
$ gem install boilerpl8
$ boilerpl8 --help
```


Examples
--------

For Ruby project:

```console
### download boilerplate files from github.com/kwatch/hello-ruby-boilerpl8
$ boilerpl8 github:kwatch/hello-ruby myproj
```

For Keight.rb framework:

```console
### download boilerplate files from github.com/kwatch/keight-ruby-boilerpl8
$ boilerpl8 github:kwatch/keight-ruby myapp1
```

For HTML5 web site:

```console
### download boilerplate files from github.com/h5bp/html5-boilerplate
### ('-B' option doesn't append '-boilerpl8' to github repo name.)
$ boilerpl8 -B github:h5bp/html5-boilerplate website1
```

You can expand local *.zip or *.tar.gz file:

```console
$ url="https://github.com/kwatch/hello-ruby-boilerpl8/archive/v0.2.0.zip"
$ wget -O hello-ruby-v0.2.0.zip $url
$ ls hello-ruby-v0.2.0.zip
hello-ruby-v0.2.0.zip
$ boilerpl8 file:hello-ruby-v0.2.0.zip myapp1
```


Todo
----

* [_] List github repositories which name ends with `-boilerpl8`.


License
-------

MIT License
