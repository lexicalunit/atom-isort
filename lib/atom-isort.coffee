module.exports =

class AtomIsort
  ################
  ## Public API ##
  ################
  constructor: (pythonEnv) ->
    @pythonEnv = pythonEnv

  checkImports: (editor = null, useEntireEditor = false) ->
    @isortRequest 'check_text', useEntireEditor, editor

  sortImports: (editor = null, useEntireEditor = false) ->
    @isortRequest 'sort_text', useEntireEditor, editor

  ############################
  ## Private Implementation ##
  ############################
  issueReportLink: 'https://github.com/lexicalunit/atom-isort/issues/new'

  isPythonContext: (editor) ->
    return false if not editor?
    editor.getGrammar().scopeName == 'source.python'

  getFilePath: ->
    atom.workspace.getActiveTextEditor().getPath()

  getFileDir: ->
    atom.project.relativizePath(@getFilePath())[0]

  isortRequest: (requestType, useEntireEditor, editor = null) ->
    editor = atom.workspace.getActiveTextEditor() if not editor?
    return null if not @isPythonContext editor

    # Get selected text if there is any, else whole editor.
    if editor.getSelectedBufferRange().isEmpty() or useEntireEditor
      sourceText = editor.getText()
      insertType = 'set'
    else
      sourceText = editor.getSelectedText()
      insertType = 'insert'

    payload =
      type: requestType
      file_contents: sourceText
      file_path: editor.getPath()

    pyResponse = require('child_process').spawnSync(
      'python',
      [__dirname + '/atom-isort.py'],
      {env: @pythonEnv, input: "#{JSON.stringify(payload)}\n"}
    )

    if pyResponse.error?
      if pyResponse.error.code == 'ENOENT'
        atom.notifications.addError """
          Atom-isort was unable to find your machine's python executable.
          Please try setting the path in package settings, and then restart atom.
          Consider posting an issue on: #{@issueReportLink}
          """,
          detail: pyResponse.error,
          dismissable: true
      else
        atom.notifications.addError """
          Atom-isort encountered an unexpected error.
          Consider posting an issue on: #{@issueReportLink}
          """,
          dismissable: true
      return null

    if pyResponse.stderr? and pyResponse.stderr.length > 0
      atom.notifications.addError """
        Atom-isort experienced an unexpected exit of the python process.
        Consider posting an issue on: #{@issueReportLink}
        """,
        detail: "exit with error: #{pyResponse.stderr}",
        dismissable: true
      return null

    @handleIsortResponse JSON.parse(pyResponse.stdout), insertType, editor, this

  handleIsortResponse: (response, insertType = 'set', editor = null, self = this) ->
    editor = atom.workspace.getActiveTextEditor() if not editor?

    if response['type'] == 'sort_text_response' and response['new_contents']?
      if response['new_contents'].length > 0
        if insertType == 'set'
          pos = editor.getCursorScreenPosition()
          editor.setText response['new_contents']
          editor.setCursorScreenPosition pos
          return true
        else if insertType == 'insert'
          editor.insertText response['new_contents']
          return false # can not guarantee the entire file is properly isorted
      else
        atom.notifications.addInfo 'atom-isort could not find any results.'
        return false
    else if response['type'] == 'check_text_response' and response['correctly_sorted']?
      return response['correctly_sorted']
    else
      atom.notifications.addError """
        Atom-isort encountered an error: Incomplete json response from python.
        Consider posting an issue on:
        #{@issueReportLink}
        """,
        detail: JSON.stringify(response)
        dismissable: true
      return false
