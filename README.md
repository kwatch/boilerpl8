============
Boilerpl8.py
============

($Release: 0.0.0 $)


Abount
------

Boilerpl8.py is a scaffolding tool to download and expand boilerplate files.


Install
-------

```console
$ pip install boilerpl8
$ boilerpl8 --help
```

Boilerpl8.py requires Python 2.7, 3.3 or later.


Examples
--------

For Python project:

```console
### download boilerplate files from github.com/kwatch/hello-python-boilerpl8
$ boilerpl8 github:kwatch/hello-python myproj
```

For Keight.py framework:

```console
### download boilerplate files from github.com/kwatch/keight-python-boilerpl8
$ boilerpl8 github:kwatch/keight-python myapp1
```

For HTML5 web site:

```console
### download boilerplate files from github.com/h5bp/html5-boilerplate
### ('-B' option doesn't append '-boilerpl8' to github repo name.)
$ boilerpl8 -B github:h5bp/html5-boilerplate website1
```

You can expand local *.zip or *.tar.gz file:

```console
$ url="https://github.com/kwatch/hello-python-boilerpl8/archive/v0.1.0.zip"
$ wget -O hello-python-v0.1.0.zip $url
$ ls hello-python-v0.1.0.zip
hello-python-v0.1.0.zip
$ boilerpl8 file:hello-ruby-v0.1.0.zip myapp1
```


License
-------

MIT License
