module.exports =
  config:
    pythonPath:
      title: 'Path to python directory'
      type: 'string'
      default: ''
      description: '''
      Optional. Set it if default values are not working for you or you want to
      use a specific python version. For example: `/usr/local/bin`,
      `~/anaconda/bin`, or `E:\\Python2.7`.
      '''
    sortOnSave:
      type: 'boolean'
      default: false
