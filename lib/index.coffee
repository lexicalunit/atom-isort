module.exports =
  subs: null
  editorSubs: null
  pi: null
  linter: null

  config:
    pythonPath:
      type: 'string'
      default: ''
      title: 'Path to python directory'
      description: '''
      Optional. Set it if default values are not working for you or you want to use specific
      python version. For example: `/usr/local/Cellar/python/2.7.3/bin` or `E:\\Python2.7`
      '''
    sortOnSave:
      type: 'boolean'
      default: false

  setupEnv: ->
    delimiter = require('path').delimiter
    env = process.env
    pythonPath = atom.config.get 'editor-isort.pythonPath'
    envPath = null

    if /^win/.test(process.platform)
      paths = [
        'C:\\Python2.7'
        'C:\\Python3.4'
        'C:\\Python34'
        'C:\\Python3.5'
        'C:\\Python35'
        'C:\\Program Files (x86)\\Python 2.7'
        'C:\\Program Files (x86)\\Python 3.4'
        'C:\\Program Files (x86)\\Python 3.5'
        'C:\\Program Files (x64)\\Python 2.7'
        'C:\\Program Files (x64)\\Python 3.4'
        'C:\\Program Files (x64)\\Python 3.5'
        'C:\\Program Files\\Python 2.7'
        'C:\\Program Files\\Python 3.4'
        'C:\\Program Files\\Python 3.5'
      ]
      envPath = (env.Path or '')
    else
      paths = ['/usr/local/bin', '/usr/bin', '/bin', '/usr/sbin', '/sbin']
      envPath = (env.PATH or '')

    envPath = envPath.split(delimiter)
    envPath.unshift(pythonPath if pythonPath and pythonPath not in envPath)
    for p in paths
      if p not in envPath
        envPath.push(p)
    env.PATH = envPath.join(delimiter)
    return env

  handleEvents: (pi) ->
    {CompositeDisposable} = require 'atom'
    @subs = new CompositeDisposable
    @editorSubs = new CompositeDisposable
    @subs.add atom.commands.add 'atom-text-editor[data-grammar="source python"]',
      'atom-isort:sort imports', ->
        pi.sortImports()
    @subs.add atom.config.observe 'atom-isort.sortOnSave', (value) =>
      @editorSubs.add atom.workspace.observeTextEditors (editor) ->
        if value
          editor._isortSortOnWillSave = editor.buffer.onWillSave -> pi.sortImports editor, true
        else
          editor._isortSortOnWillSave?.dispose()

  activate: ->
    console.log 'activate atom-isort' if atom.inDevMode()
    require('atom-package-deps').install 'atom-isort'
    AtomIsort = require './atom-isort'
    @pi = new AtomIsort @setupEnv()
    @handleEvents @pi

  provideLinter: ->
    AtomIsortLinter = require './atom-isort-linter'
    @linter = new AtomIsortLinter @pi if not @linter
    return @linter

  deactivate: ->
    for editor in atom.workspace.getTextEditors()
      editor._isortSortOnWillSave?.dispose()
    @linter = null
    @pi = null
    @editorSubs?.dispose()
    @editorSubs = null
    @subs?.dispose()
    @subs = null
