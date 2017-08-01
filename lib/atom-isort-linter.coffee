module.exports =

class AtomIsortLinter
  name: 'isort'
  scope: 'file'
  lintsOnChange: false
  grammarScopes: ['source.python']

  constructor: (pi) ->
    @pi = pi

  lint: (textEditor) ->
    sorted = @pi.checkImports textEditor, true
    return [] if sorted
    return [{
      severity: 'warning'
      location: {
        file: textEditor.getPath()
        position: [[0, 0], [0, 0]]
      }
      excerpt: 'Imports not sorted'
      linterName: 'isort'
    }]
