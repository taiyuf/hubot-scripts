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
    "<strong>#{str}</strong>"

  url: (title, url) ->
    "<a href='#{u_str}' target='_blank'>#{t_str}</a>"

  underline: (str) ->
    "<u>#{str}</u>"

  send: (target, msg) ->

    if @infoFile
      unless @infoFlag
        @info    = @config.get @infoFile
        @infoFlag = true

    unless @msgType
      @log.warn 'Please set the value at HUBOT_IRC_MSG_TYPE.'
      @log.warn '"string" type has selected.'
    unless @msgLabel
      @log.warn 'Please set the value at HUBOT_IRC_MSG_LABEL.'
      return

    @form[@msgLabel] = @msg_filter msg

    if @info.header
      @header = @info.header

    if @header
      @request.post
        url: target
        headers: @header
        form: @form
      , (err, response, body) ->
        log.warn err, 'err: ' if err
    else
      @request.post
        url: target
        form: @form
      , (err, response, body) ->
        @log.warn err, 'err: ' if err

module.exports = HttpPostMessage
