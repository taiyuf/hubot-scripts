class IrcMessage

  constructor: (robot) ->

    @robot       = robot
    @request     = require 'request'
    @querystring = require 'querystring'
    @msgLabel    = 'text'
    @lineFeed    = "\n"
    @prefix      = "[send_message]"

  bold: (str) ->
    "\x02" + str + "\x02"

  url: (title, url) ->
    "\x1f" + t_str + "\x1f" + ": " + u_str

  underline: (str) ->
    "\x1f" + str + "\x1f"

  send: (target, msg) ->

    if typeof(msg) == 'object'
      messages = msg.join(@lineFeed)
    else
      if typeof(msg) == 'string'
        messages = msg
      else
        console.log "#{@prefix} unknown message type: " + typeof(msg) + "."

    for tg in target
      @robot.send { 'room': tg }, messages

module.exports = IrcMessage
