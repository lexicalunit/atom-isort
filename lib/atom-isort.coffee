module.exports =
class AtomIsort
  statusDialog: null

  # TODO: might be better to do python context check in index.coffee, via:

  # @subs.add atom.commands.add 'atom-text-editor[data-grammar="source python"]',
  #   'atom-isort:sortImports', -> pi.sortImports()

  # which stops the command from showing up in other editor contexts

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

  getFileDir: ->
    return atom.project.relativizePath(@getFilePath())[0]

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
    options = {cwd: @getFileDir()}

    process = require 'child_process'
    exit_code = process.spawnSync(isortPath, params, options).status
    if exit_code == 127
      @updateStatusbarText '?', false
    else if exit_code != 0
      @updateStatusbarText 'x', false
    else
      @updateStatusbarText '√', true
