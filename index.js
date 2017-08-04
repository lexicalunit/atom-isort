/** @babel */

function getPythonEnvironment () {
  const {delimiter} = require('path')
  const {env} = process
  const pythonPath = atom.config.get('atom-isort.pythonPath')

  let paths = []
  let envPath = null
  if (/^win/.test(process.platform)) {
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
    envPath = (env.Path || '')
  } else {
    paths = ['/usr/local/bin', '/usr/bin', '/bin', '/usr/sbin', '/sbin']
    envPath = (env.PATH || '')
  }

  envPath = envPath.split(delimiter)
  envPath.unshift(pythonPath && !Array.from(envPath).includes(pythonPath) ? pythonPath : undefined)
  for (let p of Array.from(paths)) {
    if (!Array.from(envPath).includes(p)) envPath.push(p)
  }
  env.PATH = envPath.join(delimiter)
  return env
}

export default {
  config: require('./lib/config.coffee').config,

  activate () {
    if (atom.inDevMode()) console.log('activate atom-isort')
    require('atom-package-deps').install('atom-isort')
    const Sorter = require('./lib/sorter')
    this.sorter = new Sorter(getPythonEnvironment())
    this.linter = null
    this.handleEvents()
  },

  handleEvents () {
    const {CompositeDisposable} = require('atom')
    this.subs = new CompositeDisposable()
    this.editorSubs = new CompositeDisposable()
    this.subs.add(
      atom.commands.add(atom.workspace, 'atom-isort:sort imports', () => {
        this.sorter.sortImports(atom.workspace.getActiveTextEditor())
      })
    )

    this.subs.add(atom.config.observe('atom-isort.sortOnSave', (sortOnSave) => {
      this.editorSubs.add(atom.workspace.observeTextEditors((textEditor) => {
        if (sortOnSave) {
          textEditor._isortSortOnWillSave =
            textEditor.buffer.onWillSave(() => this.sorter.sortImports(textEditor, true))
        } else {
          __guard__(textEditor._isortSortOnWillSave, x => x.dispose())
        }
      }))
    }))
  },

  provideLinter () {
    const Linter = require('./lib/linter')
    if (!this.linter) this.linter = new Linter(this.sorter)
    return this.linter
  },

  deactivate () {
    for (let editor of Array.from(atom.workspace.getTextEditors())) {
      __guard__(editor._isortSortOnWillSave, x => x.dispose())
    }

    __guard__(this.editorSubs, x => x.dispose())
    this.editorSubs = null

    __guard__(this.subs, x => x.dispose())
    this.subs = null

    this.linter = null
    this.sorter = null
  }
}

function __guard__ (value, transform) {
  return (typeof value !== 'undefined' && value !== null)
    ? transform(value)
    : undefined
}
