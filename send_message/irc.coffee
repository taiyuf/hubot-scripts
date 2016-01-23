class IrcMessage

  Log    = require '../log'
  Config = require '../config'

  constructor: (robot) ->

    @robot       = robot
    @fs          = require 'fs'
    @request     = require 'request'
    @querystring = require 'querystring'
    @form        = {}
    @msgLabel    = 'text'
    @lineFeed    = "\n"
    @log         = new Log 'send_message'
    @config      = new Config


  bold: (str) ->
    "\x02" + str + "\x02"

  url: (title, url) ->
    "\x1f" + t_str + "\x1f" + ": " + u_str

  underline: (str) ->
    "\x1f" + str + "\x1f"

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
