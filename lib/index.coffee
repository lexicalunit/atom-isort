module.exports =
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

  status: null
  subs: null

  activate: ->
    AtomIsort = require './atom-isort'
    pi = new AtomIsort()

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

    StatusDialog = require './status-dialog'
    @status = new StatusDialog pi
    pi.setStatusDialog(@status)

  deactivate: ->
    @subs?.dispose()
    @subs = null
    @status?.dispose()
    @status = null

  consumeStatusBar: (statusBar) ->
    @status.attach statusBar
