/** @babel */

describe('Atom Isort', () => {
  let AtomIsort

  beforeEach(() => {
    waitsForPromise(() => {
      return atom.packages.activatePackage('language-python')
    })
    waitsForPromise(() => {
      return atom.packages.activatePackage('atom-isort').then(pack => {
        AtomIsort = pack.mainModule
      })
    })
  })

  describe('when no text is selected', () => {
    it('runs isort on the entire file', () => {
      waitsForPromise(() => {
        return atom.workspace.open('unsorted.py')
          .then((editor) => {
            AtomIsort.sorter.sortImports(editor)
            const e = atom.workspace.getActiveTextEditor()
            expect(e.getText()).toBe(`\
import io
import json
import sys

import isort
\
`)
          })
      })
    })
  })

  describe('when some text is selected', () => {
    it('runs isort on the selected text', () => {
      waitsForPromise(() => {
        return atom.workspace.open('unsorted.py')
          .then((editor) => {
            editor.setSelectedBufferRange([[0, 0], [2, 0]])
            AtomIsort.sorter.sortImports(editor)
            expect(editor.getText()).toBe(`\
import json
import sys

import isort



import io
\
`)
          })
      })
    })
  })
})
