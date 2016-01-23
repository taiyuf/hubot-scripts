class IrcMessage

  Log = require '../log'

  constructor: (robot) ->

    @robot       = robot
    @fs          = require 'fs'
    @request     = require 'request'
    @querystring = require 'querystring'
    @form        = {}
    @msgLabel    = 'text'
    @lineFeed    = "\n"
    @log         = new Log 'send_message'


  bold: (str) ->
    "\x02" + str + "\x02"

  url: (title, url) ->
    "\x1f" + t_str + "\x1f" + ": " + u_str

  underline: (str) ->
    "\x1f" + str + "\x1f"

  readJson: (file, prefix) ->

    unless prefix
      prefix = @prefix

    unless file
      @log.warn 'Please set the value of "file".'
      return

    unless prefix
      @log.warn "Error occured in loading the file \"#{file}\"."
      @log.warn 'Please set the value of "prefix".'
      return

    try
      data = @fs.readFileSync file, 'utf-8'
      try
        json = JSON.parse data
        @log.info "success to load file: #{file}."
        return json
      catch
        @log.warn "Error on parsing the json file: #{file}"
        return
    catch
      @log.warn "Error on reading the json file: #{file}"
      return

  msg_filter: (msg) ->
    if typeof(msg) is 'object'
      messages = msg.join(@lineFeed)
    else
      if typeof(msg) is 'string'
        messages = msg
      else
        @log.warn "#{@prefix} unknown message type: " + typeof(msg) + "."
        return

  htmlFilter: (msg) ->
    msg.replace(/<br>/g, @lineFeed)
    .replace(/<br \/>/g, @lineFeed)
    .replace(/<("[^"]*"|'[^']*'|[^'">])*>/g, '')
    .replace(/^$/g, '')
    .replace(/^#{@lineFeed}$/g, '')

  send: (target, msg) ->
    @robot.send { 'room': target }, @msg_filter(msg)

module.exports = IrcMessage
