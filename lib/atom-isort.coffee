module.exports =
class AtomIsort
  statusDialog: null
  _issueReportLink: 'None yet' #TODO: insert issue report url.

  # TODO: might be better to do python context check in index.coffee, via:

  # @subs.add atom.commands.add 'atom-text-editor[data-grammar="source python"]',
  #   'atom-isort:sortImports', -> pi.sortImports()

  # which stops the command from showing up in other editor contexts

  isPythonContext: (editor) ->
    if not editor?
      return false
    return editor.getGrammar().scopeName == 'source.python'

  setStatusDialog: (dialog) ->
    @statusDialog = dialog

  removeStatusbarItem: ->
    @statusBarTile?.destroy()
    @statusBarTile = null

  updateStatusbarText: (message, success) ->
    @statusDialog?.update message, success

  getFilePath: ->
    return atom.workspace.getActiveTextEditor().getPath()

  getFileDir: ->
    return atom.project.relativizePath(@getFilePath())[0]

  # TODO: impliment check imports.
  # checkImports: (editor = null) ->
  #   @runIsort 'check', editor

  sortImports: (editor = null) ->
    @send_python_isort_request 'sort_text', editor

  applySubstitutions: (p) ->
    path = require 'path'

    for project in atom.project.getPaths()
      [..., projectName] = project.split(path.sep)
      p = p.replace(/\$PROJECT_NAME/i, projectName)
      p = p.replace(/\$PROJECT/i, project)
    return p

  generate_python_provider: () ->
    env = this.python_env
    this.provider = require('child_process').spawn(
      'python', [__dirname + '/atom-isort.py'], env: env
    )
    this.readline = require('readline').createInterface({
      input: this.provider.stdout,
      output: this.provider.stdin
    } )

    # TODO: standardize error messages
    this.provider.on('error', (err) =>
      if err.code == 'ENOENT'
        atom.notifications.addWarning("""
          atom - isort was unable to find your machine's python executable.
          Please try set the path in package settings and then restart atom.
          If the issue persists please post an issue on
          #{this._issueReportLink}
          """, {
            detail: err,
            dismissable: true
          }
        )
      else
        atom.notifications.addError("""
          atom - isort unexpected error.
          Please consider posting an issue on
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
          editor - isort experienced an unexpected exit.
          Please consider posting an issue on
          #{this._issueReportLink}
          """, {
            detail: "exit with code #{code}, signal #{signal}",
            dismissable: true
          }
        )
    )

  close_python_provider: () ->
    this.provider.kill()
    this.readline.close()

  send_python_isort_request: (request_type, editor = null) ->
    editor = atom.workspace.getActiveTextEditor() if not editor?
    this.generate_python_provider()
    if not this.provider?
      atom.notifications.addError('Python provider could not connect.')

    # Get selected text if there is any, else whole editor.
    if editor.getSelectedBufferRange().isEmpty()
      source_text = editor.getText()
      insert_type = 'set'
    else
      source_text = editor.getSelectedText()
      insert_type = 'insert'

    # TODO: read options from cfg, eg: line max-length from editor settings
    payload = {
      type: request_type,
      source: source_text
    }

    # This is needed for the promise scope to work correctly
    handle_python_isort_response = this.handle_python_isort_response
    readline = this.readline
    self = this

    return new Promise((resolve, reject) ->
      response = readline.question("#{JSON.stringify(payload)}\n", (response) ->
        handle_python_isort_response(JSON.parse(response), insert_type, editor, self)
        resolve()
      )
    )


  handle_python_isort_response: (
      response, insert_type = 'set', editor = null, self = this) ->
    editor = atom.workspace.getActiveTextEditor() if not editor?
    if response['type'] == 'error'
      console.error(response['error'])
      atom.notifications.addError(response['error'])
      # AtomIsort.updateStatusbarText '?', false
      self.close_python_provider()
      return

    if response['type'] == 'sort_text_response'
      if response['new_contents'].length > 0
        if insert_type == 'set'
          editor.setText(response['new_contents'])
        else if insert_type == 'insert'
          editor.insertText(response['new_contents'])
        # AtomIsort.updateStatusbarText '√', true

      else
        atom.notifications.addInfo("atom-isort could not find any results!")
        # AtomIsort.updateStatusbarText '?', false
    else
      atom.notifications.addError(
        "atom-isort error. #{this._issueReportLink}", {
          detail: JSON.stringify(response),
          dismissable: true
        }
      )
      # AtomIsort.updateStatusbarText '?', false

    self.close_python_provider()
    return

  runIsort: (mode, editor = null) ->
    atom.notifications.addInfo("Defaulted to old isort")
    editor = atom.workspace.getActiveTextEditor() if not editor
    if not @isPythonContext atom.workspace.getActiveTextEditor()
      return

    fs = require 'fs-plus'
    hasbin = require 'hasbin'

    isortPath = fs.normalize atom.config.get 'atom-isort.isortPath'
    isortPath = @applySubstitutions(isortPath)
    if not fs.existsSync(isortPath) and not hasbin.sync(isortPath)
      @updateStatusbarText 'unable to open ' + isortPath, false
      return

    params = ['-ns', @getFilePath(), '-vb']
    if mode == 'sort'
      @updateStatusbarText '⧗', true
    else if mode == 'check'
      params = params.concat ['-c']
    else
      return
    params = params.concat [@getFilePath()]
    options = {cwd: @getFileDir()}

    process = require 'child_process'
    exit_code = process.spawnSync(isortPath, params, options).status
    if exit_code == 127
      @updateStatusbarText '?', false
    else if exit_code != 0
      @updateStatusbarText 'x', false
    else
      @updateStatusbarText '√', true
