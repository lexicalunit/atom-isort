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
    return true if editor.isEmpty()

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

    if editor.getPath()
      payload['file_path'] = editor.getPath()
    else
      atom.notifications.addWarning '''
        Running isort on an unsaved file.
        Settings detection for isort may not work correctly.
        ''',
        dismissable: true

    pythonProgram = 'python'
    pythonArgs = [__dirname + '/atom-isort.py']
    try
      stdinInput = "#{JSON.stringify(payload)}\n"
    catch error
      atom.notifications.addError 'Failed to construct isort input payload.',
        detail: "Payload: #{payload}"
        dismissable: true
      return null
    spawnOptions = {env: @pythonEnv, input: stdinInput}
    pyResponse = require('child_process').spawnSync(pythonProgram, pythonArgs, spawnOptions)

    if pyResponse.error?
      if pyResponse.error.code == 'ENOENT'
        atom.notifications.addError '''
          Unable to find your python executable.
          Please upte the path to your python executable in the package settings, and restart Atom.
          ''',
          detail: pyResponse.error,
          dismissable: true
      else
        atom.notifications.addError 'Encounted an unexpected error.',
          detail: pyResponse.error,
          dismissable: true
      return null

    if pyResponse.stderr? and pyResponse.stderr.length > 0
      atom.notifications.addError 'Unexpected errors while running python process.',
        detail: "#{pyResponse.stderr}",
        dismissable: true
      return null

    try
      response = JSON.parse(pyResponse.stdout)
    catch error
      atom.notifications.addError 'Could not parse isort response.',
        detail: "#{pyResponse.stdout}"
        dismissable: true
      return null
    @handleIsortResponse response, insertType, editor

  handleIsortResponse: (response, insertType = 'set', editor = null) ->
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
        atom.notifications.addInfo 'atom-isort could not find any results.',
          dismissable: true
        return false
    else if response['type'] == 'check_text_response' and response['correctly_sorted']?
      return response['correctly_sorted']
    else
      atom.notifications.addError 'Incomplete response from python.',
        detail: "#{response}"
        dismissable: true
      return false
