# atom-isort

[![apm package][apm-ver-link]][releases]
[![travis-ci][travis-ci-badge]][travis-ci]
[![appveyor][appveyor-badge]][appveyor]
[![david][david-badge]][david]
[![download][dl-badge]][apm-pkg-link]
[![mit][mit-badge]][mit]

Atom.io plugin to format and sort Python imports using [isort][isort].

![Screenshot][screenshot]

## Prerequisites

Make sure you have `isort` and `python` installed. Set the `python` installation
in the package configuration if necessary. As for installation of `isort`, there
are good options such as [`conda`][conda] or [`pip`][pip].

## Acknowledgements

Heavily influenced by Benjamin Hedrich's [atom-python-isort][atom-python-isort]
as well as blacktop's [atom-python-yapf][atom-python-yapf]. This package is a
more up to date and actively developed version of `atom-python-isort`.

---

[MIT][mit] © [lexicalunit][author] et [al][contributors]

[mit]:                  http://opensource.org/licenses/MIT
[author]:               http://github.com/lexicalunit
[contributors]:         https://github.com/lexicalunit/atom-isort/graphs/contributors
[releases]:             https://github.com/lexicalunit/atom-isort/releases
[mit-badge]:            https://img.shields.io/apm/l/atom-isort.svg
[apm-pkg-link]:         https://atom.io/packages/atom-isort
[apm-ver-link]:         https://img.shields.io/apm/v/atom-isort.svg
[dl-badge]:             http://img.shields.io/apm/dm/atom-isort.svg
[travis-ci-badge]:      https://travis-ci.org/lexicalunit/atom-isort.svg?branch=master
[travis-ci]:            https://travis-ci.org/lexicalunit/atom-isort
[appveyor]:             https://ci.appveyor.com/project/lexicalunit/atom-isort?branch=master
[appveyor-badge]:       https://ci.appveyor.com/api/projects/status/mjla5e3rynka5uro/branch/master?svg=true
[david-badge]:          https://david-dm.org/lexicalunit/atom-isort.svg
[david]:                https://david-dm.org/lexicalunit/atom-isort

[screenshot]:           https://raw.githubusercontent.com/lexicalunit/atom-isort/master/example_sorting.gif
[conda]:                https://conda.io/docs/intro.html
[pip]:                  https://pip.pypa.io/en/latest/
[isort]:                https://github.com/timothycrosley/isort
[atom-python-isort]:    https://github.com/bh/atom-python-isort
[atom-python-yapf]:     https://github.com/blacktop/atom-python-yapf
