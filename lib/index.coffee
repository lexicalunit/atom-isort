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
      description: 'Requires restart to show again.'
    pythonPath:{
      type: 'string'
      default: ''
      title: 'Path to python directory',
      description: ''',
      Optional. Set it if default values are not working for you or you want to use specific
      python version. For example: `/usr/local/Cellar/python/2.7.3/bin` or `E:\\Python2.7`
      '''}

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

    @subs.add atom.commands.add 'atom-text-editor[data-grammar="source python"]','atom-isort:sortImports', ->
      pi.sortImports()

    @subs.add atom.commands.add 'atom-text-editor[data-grammar="source python"]','atom-isort:checkImports', ->
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
          if pi.statusDialog?
            pi.removeStatusbarItem()
        else
          # TODO: this isn't working, not sure how to get it to. Scope in JS
          # is confusing. Need to call consumeStatusBar?
          pi.addStatusDialog()
          @status = pi.statusDialog

    if atom.config.get('atom-isort.showStatusBar')
      pi.addStatusDialog()
    # status = new StatusDialog pi
    # pi.setStatusDialog(status)

    @status = pi.statusDialog
    @pi = pi

  deactivate: ->
    @subs?.dispose()
    @subs = null
    @status?.detach()
    @status = null
    @pi.close_python_provider()
    @pi = null

  consumeStatusBar: (statusBar) ->
    if atom.config.get('atom-isort.showStatusBar')
      @status.attach statusBar
