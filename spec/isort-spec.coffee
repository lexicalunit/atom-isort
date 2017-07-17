describe 'Atom Isort', ->
  [AtomIsort] = []

  beforeEach ->
    waitsForPromise -> atom.packages.activatePackage('language-python')
    waitsForPromise ->
      atom.packages.activatePackage('atom-isort').then (pack) ->
        AtomIsort = pack.mainModule

  describe 'when no text is selected', ->
    it 'runs isort on the entire file', ->
      waitsForPromise ->
        atom.workspace.open('unsorted.py')
          .then (editor) ->
            AtomIsort.pi.sortImports editor
            e = atom.workspace.getActiveTextEditor()
            expect(e.getText()).toBe """
              import io
              import json
              import sys

              import isort

            """

  describe 'when some text is selected', ->
    it 'runs isort on the selected text', ->
      waitsForPromise ->
        atom.workspace.open('unsorted.py')
          .then (editor) ->
            editor.setSelectedBufferRange([[0, 0], [2, 0]])
            AtomIsort.pi.sortImports editor
            expect(editor.getText()).toBe """
              import json
              import sys

              import isort



              import io

            """

# TODO: Implement the following missing spec tests.
#
# - runs isort sort on save
# - runs isort check on save
# - isort check returns correct results
# - status bar widget exists if status bar widget is enabled
# - notifications are presented if notifications are enabled
