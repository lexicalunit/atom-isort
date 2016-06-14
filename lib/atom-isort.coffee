fs = require 'fs-plus'
$ = require 'jquery'
process = require 'child_process'

module.exports =
class AtomIsort
  statusDialog: null

  isPythonContext: (editor) ->
    if not editor?
      return false
    return editor.getGrammar().scopeName == 'source.python'

  setStatusDialog: (dialog) ->
    @statusDialog = dialog

  removeStatusbarItem: ->
    @statusBarTile?.destroy()
    @statusBarTile = null

  updateStatusbarText: (message, success) ->
    @statusDialog.update message, success

  getFilePath: ->
    return atom.workspace.getActiveTextEditor().getPath()

  checkImports: ->
    @runIsort 'check'

  sortImports: ->
    @runIsort 'sort'

  runIsort: (mode) ->
    if not @isPythonContext atom.workspace.getActiveTextEditor()
      return

    isortPath = fs.normalize atom.config.get 'atom-isort.isortPath'
    if not fs.existsSync isortPath
      @updateStatusbarText 'unable to open ' + isortPath, false
      return

    params = ['-vb']
    if mode == 'sort'
      @updateStatusbarText '⧗', true
    else if mode == 'check'
      params = params.concat ['-c']
    else
      return
    params = params.concat [@getFilePath()]

    proc = process.spawn isortPath, params
    output = []
    proc.stdout.setEncoding 'utf8'
    proc.stdout.on 'data', (chunk) ->
      output.push chunk
    proc.stdout.on 'end', (chunk) ->
      output.join()
    proc.on 'exit', (exit_code, signal) =>
      if exit_code != 0
        @updateStatusbarText 'x', false
      else
        @updateStatusbarText '√', true
