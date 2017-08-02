/** @babel */

import path from 'path'

export default class Sorter {
  constructor (pythonEnv) {
    this.pythonEnv = pythonEnv
  }

  /** Checks if imports are sorted and returns true iff they are. */
  checkImports (textEditor) {
    return isortRequest('check_text', this.pythonEnv, true, textEditor)
  }

  /** Sorts imports in-place and returns true iff the entire file is properly isorted. */
  sortImports (textEditor, useEntireEditor = false) {
    return isortRequest('sort_text', this.pythonEnv, useEntireEditor, textEditor)
  }
}

function isortRequest (requestType, pythonEnv, useEntireEditor, textEditor) {
  if (!textEditor) return false
  if (textEditor.isEmpty()) return true

  // Get selected text if there is any, otherwise isort the whole file.
  let insertType, sourceText
  if (textEditor.getSelectedBufferRange().isEmpty() || useEntireEditor) {
    sourceText = textEditor.getText()
    insertType = 'set'
  } else {
    sourceText = textEditor.getSelectedText()
    insertType = 'insert'
  }

  const payload = {
    type: requestType,
    file_contents: sourceText
  }

  if (textEditor.getPath()) {
    payload['file_path'] = textEditor.getPath()
  } else {
    warning(`Running isort on an unsaved file.
             Settings detection for isort may not work correctly.`)
  }

  const pythonProgram = 'python'
  const pythonArgs = ['-B', path.join(__dirname, '../src/isort-wrapper.py')]
  let stdinInput
  try {
    stdinInput = `${JSON.stringify(payload)}\n`
  } catch (e) {
    error('Failed to construct isort input payload.', `${e}: ${payload}`)
    return false
  }
  const spawnOptions = {env: this.pythonEnv, input: stdinInput}
  const pyResponse = require('child_process').spawnSync(pythonProgram, pythonArgs, spawnOptions)

  if (pyResponse.error != null) {
    if (pyResponse.error.code === 'ENOENT') {
      error('Unable to find your python executable. Please set the path to your python ' +
            `executable in this package's settings, and restart Atom.`, pyResponse.error)
    } else {
      error('Encounted an unexpected error.', pyResponse.error)
    }
    return false
  }

  if (pyResponse.stderr != null && pyResponse.stderr.length > 0) {
    error('Unexpected errors while running python process.', pyResponse.stderr)
    return false
  }

  let response
  try {
    // Ignore any unsilenced output from isort.SortImports() when write_to_stdout=True.
    const sentry = '__ATOM_ISORT_SENTRY__'
    const data = pyResponse.stdout.toString()
    const start = data.indexOf(sentry) + sentry.length
    response = JSON.parse(data.slice(start))
  } catch (e) {
    error('Could not parse isort response.', `${e}: ${pyResponse.stdout}`)
    return false
  }

  return handleIsortResponse(response, insertType, textEditor)
}

function handleIsortResponse (response, insertType, textEditor) {
  if (response['type'] === 'check_text_response' && response['correctly_sorted'] != null) {
    return response['correctly_sorted']
  }

  if (response['type'] === 'sort_text_response' && response['new_contents'] != null) {
    const newContents = response['new_contents']
    if (newContents.length <= 0) {
      info('Could not find any isort response.')
      return false
    }

    const pos = textEditor.getCursorScreenPosition()
    let update = async () => {
      if (insertType === 'set') textEditor.setText(newContents)
      else if (insertType === 'insert') textEditor.insertText(newContents)
      atom.commands.dispatch(atom.views.getView(textEditor), 'linter:lint')
    }
    update().then(() => {
      __guard__(textEditor, x => x.setCursorScreenPosition(pos))
    })

    // Can only not guarantee the entire file is properly isorted when type is 'set'.
    return insertType === 'set'
  }

  error('Incomplete response from isort.', response)
  return false
}

function notification (level, msg, detail) {
  let opts = { dismissable: true }
  if (detail) opts.detail = `${detail}`
  if (level === 'info') atom.notifications.addInfo(msg, opts)
  if (level === 'warning') atom.notifications.addWarning(msg, opts)
  if (level === 'error') atom.notifications.addError(msg, opts)
}
let info = (msg, detail = null) => notification('info', msg, detail)
let warning = (msg, detail = null) => notification('warning', msg, detail)
let error = (msg, detail = null) => notification('error', msg, detail)

function __guard__ (value, transform) {
  return (typeof value !== 'undefined' && value !== null)
    ? transform(value)
    : undefined
}
