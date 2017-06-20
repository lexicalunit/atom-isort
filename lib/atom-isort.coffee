module.exports =
class AtomIsort
  statusDialog: null
  _issueReportLink: 'https://github.com/lexicalunit/atom-isort/issues/new'

  isPythonContext: (editor) ->
    if not editor?
      return false
    return editor.getGrammar().scopeName == 'source.python'

  addStatusDialog: (dialog) ->
    StatusDialog = require './status-dialog'
    status = new StatusDialog this
    this.setStatusDialog(status)

  setStatusDialog: (dialog) ->
    @statusDialog?.destroy()
    @statusDialog = null
    @statusDialog = dialog

  removeStatusbarItem: ->
    @statusDialog?.destroy()
    @statusDialog = null

  updateStatusbarText: (message, success) ->
    @statusDialog?.update message, success

  getFilePath: ->
    return atom.workspace.getActiveTextEditor().getPath()

  getFileDir: ->
    return atom.project.relativizePath(@getFilePath())[0]

  checkImports: (editor = null, force_use_whole_editor = false) ->
    @send_python_isort_request 'check_text', force_use_whole_editor, editor

  sortImports: (editor = null, force_use_whole_editor = false) ->
    @send_python_isort_request 'sort_text', force_use_whole_editor, editor

  generate_python_provider: () ->
    env = this.python_env
    this.provider = require('child_process').spawn(
      'python', [__dirname + '/atom-isort.py'], env: env
    )
    this.readline = require('readline').createInterface({
      input: this.provider.stdout,
      output: this.provider.stdin
    } )

    this.provider.on('error', (err) =>
      if err.code == 'ENOENT'
        atom.notifications.addError("""
          Atom-isort was unable to find your machine's python executable.
          Please try setting the path in package settings, and then restart
          atom.
          Consider posting an issue on:
          #{this._issueReportLink}
          """, {
            detail: err,
            dismissable: true
          }
        )
      else
        atom.notifications.addError("""
          Atom-isort encountered an unexpected error.
          Consider posting an issue on:
          #{this._issueReportLink}
          """, {
              detail: err,
              dismissable: true
            }
        )
    )
    this.provider.on('exit', (code, signal) =>
      if signal != 'SIGTERM'
        atom.notifications.addError(
          """
          Atom-isort experienced an unexpected exit of the python process.
          Consider posting an issue on:
          #{this._issueReportLink}
          """, {
            detail: "exit with code #{code}, signal #{signal}",
            dismissable: true
          }
        )
    )

  close_python_provider: () ->
    this.provider?.kill()
    this.readline?.close()

  send_python_isort_request: (request_type, force_use_whole_editor, editor = null) ->
    editor = atom.workspace.getActiveTextEditor() if not editor?
    this.generate_python_provider()
    if not this.provider?
      atom.notifications.addError(
        """
        Atom-isort could not find the python process.
        Please try setting the path in package settings, and then restart atom.
        Consider posting an issue on:
        #{this._issueReportLink}
        """, {
          dismissable: true
        }
      )

    # Get selected text if there is any, else whole editor.
    if editor.getSelectedBufferRange().isEmpty() or force_use_whole_editor
      source_text = editor.getText()
      insert_type = 'set'
    else
      source_text = editor.getSelectedText()
      insert_type = 'insert'

    payload =
      type: request_type
      source: source_text
      options:
        line_length: atom.config.get(
          'atom-isort.lineLength')
        multi_line_output: atom.config.get(
          'atom-isort.multiLineOutputMode')
        balanced_wrapping: atom.config.get(
          'atom-isort.balancedWrapping')
        order_by_type: atom.config.get(
          'atom-isort.orderByType')
        combine_as_imports: atom.config.get(
          'atom-isort.combineAsImports')
        include_trailing_comma: atom.config.get(
          'atom-isort.includeTrailingComma')
        force_sort_within_sections: atom.config.get(
          'atom-isort.forceSortWithinSections')
        force_alphabetical_sort: atom.config.get(
          'atom-isort.forceAlphabeticalSort')


    # This is needed for the promise scope to work correctly
    handle_python_isort_response = this.handle_python_isort_response
    readline = this.readline
    self = this

    # readline.setPrompt("#{JSON.stringify(payload)}\n")
    # readline.prompt()
    # readline.on('line', (line) ->
    #   handle_python_isort_response(
    #         JSON.parse(line),
    #         insert_type,
    #         editor,
    #         self))
    #
    # return readline

    return new Promise((resolve, reject) ->
      response = readline.question("#{JSON.stringify(payload)}\n", (response) ->
        handle_python_isort_response(
              JSON.parse(response),
              insert_type,
              editor,
              self)
        resolve()
      )
    )


  handle_python_isort_response: (
      response, insert_type = 'set', editor = null, self = this) ->
    editor = atom.workspace.getActiveTextEditor() if not editor?
    use_status = atom.config.get('atom-isort.showStatusBar')
    if response['type'] == 'error'
      atom.notifications.addError(
        """
        Atom-isort encountered a python process error.
        Consider posting an issue on:
        #{this._issueReportLink}
        """, {
          detail: response['error'],#JSON.stringify(response),
          dismissable: true
        }
      )
      self.updateStatusbarText '?', false
      self.close_python_provider()
      return

    else if response['type'] == 'sort_text_response' and response['new_contents']?
      self.updateStatusbarText '⧗', true
      if response['new_contents'].length > 0
        if insert_type == 'set'
          editor.setText(response['new_contents'])
        else if insert_type == 'insert'
          editor.insertText(response['new_contents'])
        self.updateStatusbarText '√', true

      else
        atom.notifications.addInfo("atom-isort could not find any results.")
        self.updateStatusbarText '?', false


    else if response['type'] == 'check_text_response' and response['correctly_sorted']?
      self.updateStatusbarText '⧗', true
      if response['correctly_sorted']
        self.updateStatusbarText '√', true
        if not use_status
          atom.notifications.addSuccess('Imports are correctly sorted.',
            {dismissable:true})
      else
        self.updateStatusbarText 'x', false
        if not use_status
          atom.notifications.addWarning('Imports are incorrectly sorted.',
            {dismissable:true})
    else
      atom.notifications.addError(
        """
        Atom-isort encountered an error: Incomplete json response from python.
        Consider posting an issue on:
        #{this._issueReportLink}
        """, {
          detail: JSON.stringify(response),
          dismissable: true
        }
      )
      self.updateStatusbarText '?', false

    self.close_python_provider()
    return
