path = require('path') ;

module.exports = Index =
  config:
    isortPath:
      type: 'string'
      default: 'isort'
    sortOnSave:
      type: 'boolean'
      default: false
    checkOnSave:
      type: 'boolean'
      default: true
    showStatusBar:
      type: 'boolean'
      default: true

  status: null
  subs: null

  activate: ->
    AtomIsort = require './atom-isort'
    StatusDialog = require './status-dialog'
    env = process.env
    pythonPath = atom.config.get('editor-isort.pythonPath')
    path_env = null

    if /^win/.test(process.platform)
      paths = [
        'C:\\Python2.7',
        'C:\\Python3.4',
        'C:\\Python34',
        'C:\\Python3.5',
        'C:\\Python35',
        'C:\\Program Files (x86)\\Python 2.7',
        'C:\\Program Files (x86)\\Python 3.4',
        'C:\\Program Files (x86)\\Python 3.5',
        'C:\\Program Files (x64)\\Python 2.7',
        'C:\\Program Files (x64)\\Python 3.4',
        'C:\\Program Files (x64)\\Python 3.5',
        'C:\\Program Files\\Python 2.7',
        'C:\\Program Files\\Python 3.4',
        'C:\\Program Files\\Python 3.5'
      ]
      path_env = (env.Path or '')
    else
      paths = ['/usr/local/bin', '/usr/bin', '/bin', '/usr/sbin', '/sbin']
      path_env = (env.PATH or '')

    path_env = path_env.split(path.delimiter)
    path_env.unshift(pythonPath if pythonPath and pythonPath not in path_env)
    for p in paths
      if p not in path_env
        path_env.push(p)
    env.PATH = path_env.join(path.delimiter)

    pi = new AtomIsort()
    pi.python_env = env


    {CompositeDisposable} = require 'atom'
    @subs = new CompositeDisposable

    @subs.add atom.commands.add 'atom-workspace', 'pane:active-item-changed', ->
      pi.removeStatusbarItem()

    @subs.add atom.commands.add 'atom-workspace', 'atom-isort:sortImports', ->
      pi.sortImports()

    @subs.add atom.commands.add 'atom-workspace', 'atom-isort:checkImports', ->
      pi.checkImports()

    @subs.add atom.config.observe 'atom-isort.sortOnSave', (value) ->
      atom.workspace.observeTextEditors (editor) ->
        if value
          editor._isortSort = editor.onDidSave -> pi.sortImports()
        else
          editor._isortSort?.dispose()

    @subs.add atom.config.observe 'atom-isort.checkOnSave', (value) ->
      atom.workspace.observeTextEditors (editor) ->
        if value
          editor._isortCheck = editor.onDidSave -> pi.checkImports()
        else
          editor._isortCheck?.dispose()

    @subs.add atom.config.observe 'atom-isort.showStatusBar', (value) ->
      atom.workspace.observeTextEditors (editor) ->
        if not value
          pi?.removeStatusbarItem()
        else
          # TODO: this isn't working, not sure how to get it to. Scope in JS
          # is confusing.
          Index.status = new StatusDialog pi
          pi.setStatusDialog(Index.status)


    @status = new StatusDialog pi
    pi.setStatusDialog(@status)


    @pi = pi

  deactivate: ->
    @subs?.dispose()
    @subs = null
    @status?.detach()
    @status = null
    @pi.close_python_provider()
    @pi = null
    # TODO: Make deactivate call pi.close_python_provider

  consumeStatusBar: (statusBar) ->
    @status.attach statusBar
