{CompositeDisposable} = require 'atom'
{View} = require 'atom-space-pen-views'

module.exports =

class IsortStatus extends View
  subs: null
  tile: null

  @content: ->
    @div class: "status-bar-python-isort inline-block"

  initialize: (@pi) ->
    @subs = new CompositeDisposable
    this

  destroy: ->
    @tile?.destroy()
    @tile = null
    @sub?.dispose()
    @sub = null

  createElement: (type, classes...) ->
    element = document.createElement(type)
    element.classList.add classes...
    element

  update: (note, success) ->
    @hideTile()

    editor = atom.workspace.getActiveTextEditor()
    if editor and @pi.isPythonContext editor
      @tile = @statusBar?.addLeftTile
        item: this
        priority: 9

      title = @createElement 'span'
      title.style.fontWeight = 'bold'
      title.textContent = 'isort: '
      @append title

      message = @createElement 'span', 'python-isort-status-message'
      message.textContent = note
      if not success
        message.style.color = 'red'
      @append message

  hideTile: ->
    @empty()
    @tile?.destroy()
    @tile = null

  attach: (statusBar) ->
    @statusBar = statusBar
    @subs.add atom.workspace.onDidChangeActivePaneItem =>
      editor = atom.workspace.getActiveTextEditor()
      if editor and @pi.isPythonContext editor
        @pi.updateStatusbarText '⧗', true
        @pi.checkImports()
      else
        @hideTile()
