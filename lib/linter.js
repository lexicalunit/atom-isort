/** @babel */

let Linter

export default (
  Linter = (() => {
    Linter = class Linter {
      static initClass () {
        this.prototype.name = 'isort'
        this.prototype.scope = 'file'
        this.prototype.lintsOnChange = false
        this.prototype.grammarScopes = ['source.python']
      }

      constructor (sorter) {
        this.sorter = sorter
      }

      lint (textEditor) {
        const sorted = this.sorter.checkImports(textEditor)
        if (sorted) return []
        return [{
          severity: 'warning',
          location: {
            file: textEditor.getPath(),
            position: [[0, 0], [0, 0]]
          },
          excerpt: 'Imports not sorted'
        }]
      }
    }

    Linter.initClass()
    return Linter
  })()
)
