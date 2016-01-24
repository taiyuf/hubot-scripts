# Log = require './log'
# log = new Log 'logs/server.log', 'server'
# log.debug "hoge", "*** "
#
class Log

  log4js    = require 'log4js'
  env       = process.env.NODE_ENV || 'development'

  constructor: (tag)->
    @log = log4js.getLogger tag

  # Check type of argument.
  #
  # @example
  #   console.log obj.join(', ') if checktype 'Array', obj
  #
  #   available type:
  #
  #   - String
  #   - Number
  #   - Boolean
  #   - Date
  #   - Error
  #   - Array
  #   - Function
  #   - RegExp
  #   - Object
  #
  # @param  type [String]  the type it should be
  # @param  obj  [Object]  the object you want to know its type
  # @return      [Boolean] true or false
  #
  checktype: (type, obj) ->
    klass = Object.prototype.toString.call(obj).slice(8, -1)
    return obj isnt undefined && obj isnt null && klass is type


  # Write log for debug level.
  #
  # @example
  #   Log.debug 'something wrong.', 'error> '
  #   => 'error> something wrong.'
  #
  # @param message [String] the message you want to write
  # @param prefix  [String] the prefix message of log
  #
  debug: (str, prefix='') ->
    unless env is 'production'

      if @checktype 'Object', str
        try
          log = JSON.stringify str
        catch
          log = str
        @log.debug "#{prefix}#{log}"

      else if @checktype 'Array', str
        for s in str
          @log.debug "#{prefix}#{s}"

      else
        @log.debug "#{prefix}#{str}"

  # Write log for info level.
  #
  # @example
  #   log.info 'hello world.', 'server says: '
  #   => 'server say: hello world'
  #
  # @param message [String] the message you want to write
  # @param prefix  [String] the prefix message of log
  #
  info: (str, prefix='') ->
    if @checktype 'Object', str
      try
        log = JSON.stringify
      catch
        log = str
      @log.info "#{prefix}#{log}"

    else if @checktype 'Array', str
      for s in str
        @log.info "#{prefix}#{s}"

    else
      @log.info "#{prefix}#{str}"

  # Write warn log.
  #
  # @example
  #   log.warn 'something wrong!', 'error> '
  #    => 'error> something wrong!'
  #
  # @param  message [String] the message you want to write.
  # @option prefix  [String] the prefix message for error log.
  # @param  error   [String] the error message.
  #
  warn: (str, prefix='') ->
    if @checktype 'Object', str
      try
        log = JSON.stringify
      catch
        log = str
      @log.warn "#{prefix}#{log}"

    else if @checktype 'Array', str
      for s in str
        @log.warn "#{prefix}#{s}"

    else
      @log.warn "#{prefix}#{str}"

module.exports = Log
