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
    @statusDialog?.update message, success

  getFilePath: ->
    return atom.workspace.getActiveTextEditor().getPath()

  checkImports: (editor = null) ->
    @runIsort 'check', editor

  sortImports: (editor = null) ->
    @runIsort 'sort', editor

  applySubstitutions: (p) ->
    path = require 'path'

    for project in atom.project.getPaths()
      [..., projectName] = project.split(path.sep)
      p = p.replace(/\$PROJECT_NAME/i, projectName)
      p = p.replace(/\$PROJECT/i, project)
    return p

  runIsort: (mode, editor = null) ->
    editor = atom.workspace.getActiveTextEditor() if not editor
    if not @isPythonContext atom.workspace.getActiveTextEditor()
      return

    fs = require 'fs-plus'
    hasbin = require 'hasbin'

    isortPath = fs.normalize atom.config.get 'atom-isort.isortPath'
    isortPath = @applySubstitutions(isortPath)
    if not fs.existsSync(isortPath) and not hasbin.sync(isortPath)
      @updateStatusbarText 'unable to open ' + isortPath, false
      return

    params = ['-ns', @getFilePath(), '-vb']
    if mode == 'sort'
      @updateStatusbarText '⧗', true
    else if mode == 'check'
      params = params.concat ['-c']
    else
      return
    params = params.concat [@getFilePath()]

    process = require 'child_process'

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
