module.exports =
  subs: null
  editorSubs: null
  pi: null
  linter: null

  config:
    sortOnSave:
      type: 'boolean'
      default: false
      order: 1
    pythonPath:
      type: 'string'
      default: ''
      title: 'Path to python directory'
      description: '''
      Optional. Set it if default values are not working for you or you want to use specific
      python version. For example: `/usr/local/Cellar/python/2.7.3/bin` or `E:\\Python2.7`
      '''
      order: 2
    lineLength:
      type: 'integer'
      default: 80
      minimum: 1
    indent:
      type: 'integer'
      default: 4
      minimum: 1
    importHeadingFuture:
      type: 'string'
      default: ''
      description: 'A comment to consistently place directly above future imports.'
    importHeadingStdlib:
      type: 'string'
      default: ''
      description: '''
      A comment to consistently place directly above imports from the standard library.
      '''
    importHeadingThirdparty:
      type: 'string'
      default: ''
      description: 'A comment to consistently place directly above third party imports.'
    importHeadingFirstparty:
      type: 'string'
      default: ''
      description: 'A comment to consistently place directly above first party imports.'
    importHeadingLocalfolder:
      type: 'string'
      default: ''
      description: 'A comment to consistently place directly above local folder imports.'
    balancedWrapping:
      type: 'boolean'
      default: false
      description:'''
      If set to true - for each multi-line import statement isort will
      dynamically change the import length to the one that produces the most
      balanced grid, while staying below the maximum import length defined.
      '''
    orderByType:
      type: 'boolean'
      default: false
      description:'''
      If set to true - isort will create separate sections within "from" imports
       for CONSTANTS, Classes, and modules/functions.
      '''
    combineAsImports:
      type: 'boolean'
      default: false
      description: '''
      If set to true - isort will combine as imports on the same line within for
       import statements. By default isort forces all as imports to display on
       their own lines.
      '''
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
    includeTrailingComma:
      type: 'boolean'
      default: false
      description: '''
      Will set isort to automatically add a trailing comma to the end of from imports.
      '''
    forceSortWithinSections:
      type: 'boolean'
      default: false
      description: '''
      If set, imports will be sorted within their section independent to the import_type.
      '''
    forceAlphabeticalSort:
      type: 'boolean'
      default: false
      description: '''
      If set, forces all imports to be sorted as a single section, instead of
      within other groups (eg, `import os` would instead go after
      `from os import *`).
      '''

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
