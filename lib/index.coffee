path = require('path') ;

module.exports = Index =
  config:
    # TODO: add support for isort path.
    # isortPath:
    #   type: 'string'
    #   default: 'isort'
    showStatusBar:
      type: 'boolean'
      default: true
      description: 'Requires restart or reload.'
      order: 0
    sortOnSave:
      type: 'boolean'
      default: false
      order: 1
    checkOnSave:
      type: 'boolean'
      default: false
      order: 2
    pythonPath:
      type: 'string'
      default: ''
      title: 'Path to python directory',
      description: '''
      Optional. Set it if default values are not working for you or you want to use specific
      python version. For example: `/usr/local/Cellar/python/2.7.3/bin` or `E:\\Python2.7`
      '''
      order: 3
    lineLength:
      type: 'integer'
      default: 80
      minimum: 1
      order: 4
    balancedWrapping:
      type: 'boolean'
      default: false
      description:'''
      If set to true - for each multi-line import statement isort will
      dynamically change the import length to the one that produces the most
      balanced grid, while staying below the maximum import length defined.
      '''
      order: 5
    orderByType:
      type: 'boolean'
      default: false
      description:'''
      If set to true - isort will create separate sections within "from" imports
       for CONSTANTS, Classes, and modules/functions.
      '''
      order: 6
    combineAsImports:
      type: 'boolean'
      default: false
      description: '''
      If set to true - isort will combine as imports on the same line within for
       import statements. By default isort forces all as imports to display on
       their own lines.
      '''
      order: 7
    multiLineOutputMode:
      type: 'integer'
      default: 0
      minimum: 0
      maximum: 6
      description: '''
      [Full description here.](https://github.com/timothycrosley/isort#multi-line-output-modes)
      0 - Grid, 1 - Vertical, 2 - Hanging Indent, 3 - Vertical Hanging Indent,
      4 - Hanging Grid, 5 - Hanging Grid Grouped, 6 - NOQA
      '''
      order: 8
    includeTrailingComma:
      type: 'boolean'
      default: false
      description: '''
      Will set isort to automatically add a trailing comma to the end of from imports.
      '''
      order: 9
    forceSortWithinSections:
      type: 'boolean'
      default: false
      description: '''
      If set, imports will be sorted within their section independent to the
      import_type.
      '''
      order: 10
    forceAlphabeticalSort:
      type: 'boolean'
      default: false
      description: '''
      If set, forces all imports to be sorted as a single section, instead of
      within other groups (eg, `import os` would instead go after
      `from os import *`).
      '''
      order: 11

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

    if atom.config.get('atom-isort.showStatusBar')
      @subs.add atom.commands.add 'atom-workspace', 'pane:active-item-changed', ->
        pi.removeStatusbarItem()

    @subs.add atom.commands.add 'atom-text-editor[data-grammar="source python"]','atom-isort:sort imports', ->
      pi.sortImports()

    @subs.add atom.commands.add 'atom-text-editor[data-grammar="source python"]','atom-isort:check imports', ->
      pi.checkImports()

    @subs.add atom.config.observe 'atom-isort.sortOnSave', (value) ->
      atom.workspace.observeTextEditors (editor) ->
        if value
          editor._isortSort = editor.buffer.onWillSave -> pi.sortImports(editor, true)
        else
          editor._isortSort?.dispose()

    @subs.add atom.config.observe 'atom-isort.checkOnSave', (value) ->
      atom.workspace.observeTextEditors (editor) ->
        if value
          editor._isortCheck = editor.buffer.onWillSave -> pi.checkImports(editor, true)
        else
          editor._isortCheck?.dispose()

    @subs.add atom.config.observe 'atom-isort.showStatusBar', (value) ->
      atom.workspace.observeTextEditors (editor) ->
        if not value
          if pi.statusDialog?
            pi.removeStatusbarItem()
        else
          # TODO: re-adding status bar isn't working, not sure how to get it to.
          # Scope in JS is confusing. Need to call consumeStatusBar?
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
    @pi = null

  consumeStatusBar: (statusBar) ->
    if atom.config.get('atom-isort.showStatusBar')
      @status.attach statusBar
