class Config

  yaml = require 'js-yaml'
  fs   = require 'fs'

  get: (file) ->
    try
      return yaml.safeLoad fs.readFileSync(file, 'utf8')
    catch e
      console.error "Could not load #{file}: #{e}"
      return

module.exports = Config
