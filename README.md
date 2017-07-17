# atom-isort

[![apm package][apm-ver-link]][releases]
[![][david-badge]][david]
[![][dl-badge]][apm-pkg-link]
[![][mit-badge]][mit]

Atom.io plugin to format and sort Python imports using
[isort](https://github.com/timothycrosley/isort).

![Screenshot](https://raw.githubusercontent.com/lexicalunit/atom-isort/master/example_sorting.gif)

## Prerequisites

Make sure you have `isort` and `python` installed. The `python` installation path can set in the
package configuration. As for installation of `isort`, there are good options such as
[`conda`][conda] or [`pip`][pip].

## Acknowledgements

Heavily influenced by Benjamin Hedrich's
[atom-python-isort](https://github.com/bh/atom-python-isort) as well as blacktop's
[atom-python-yapf](https://github.com/blacktop/atom-python-yapf). This package is a more up to date
 and actively developed version of `atom-python-isort`.

## Future Work

- Spec tests.
- Integration with Travis CI.
- Better documentation.
- More configuration options.
- Up-to-date screenshots.

---

[MIT][mit] © [lexicalunit][author] et [al][contributors]

[mit]:              http://opensource.org/licenses/MIT
[author]:           http://github.com/lexicalunit
[contributors]:     https://github.com/lexicalunit/atom-isort/graphs/contributors
[releases]:         https://github.com/lexicalunit/atom-isort/releases
[mit-badge]:        https://img.shields.io/apm/l/atom-isort.svg
[apm-pkg-link]:     https://atom.io/packages/atom-isort
[apm-ver-link]:     https://img.shields.io/apm/v/atom-isort.svg
[dl-badge]:         http://img.shields.io/apm/dm/atom-isort.svg
[david-badge]:      https://david-dm.org/lexicalunit/atom-isort.svg
[david]:            https://david-dm.org/lexicalunit/atom-isort
[conda]:            https://conda.io/docs/intro.html
[pip]:              https://pip.pypa.io/en/latest/
