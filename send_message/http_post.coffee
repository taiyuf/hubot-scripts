IrcMessage = require './irc'

class HttpPostMessage extends IrcMessage

  constructor: (robot) ->

    super(robot)
    @msgLabel        = process.env.HUBOT_IRC_MSG_LABEL
    @msgType         = process.env.HUBOT_IRC_MSG_TYPE
    @fmtLabel        = process.env.HUBOT_IRC_FMT_LABEL
    @form[@fmtLabel] = @msgType

    if @msgType == "html"
      @lineFeed = "<br />"
    else
      @lineFeed = "\n"

  bold: (str) ->
    "<strong>" + str + "</strong>"

  url: (title, url) ->
    "<a href='" + u_str + "' target='_blank'>" + t_str + "</a>"

  underline: (str) ->
    "<u>" + str + "</u>"

  send: (target, msg) ->

    unless @msgType
      console.log "#{@prefix}: Please set the value at HUBOT_IRC_MSG_TYPE."
      console.log "#{@prefix}: \"string\" type has selected."
    unless @msgLabel
      console.log "#{@prefix}: Please set the value at HUBOT_IRC_MSG_LABEL."
      return

    unless @heades
      @request.post
        url: target
        form: @form
      , (err, response, body) ->
        console.log "err: #{err}" if err?
    else
      @request.post
        url: target
        headers: @info['header']
        form: @form
      , (err, response, body) ->
        console.log "err: #{err}" if err?

module.exports = HttpPostMessage
