IrcMessage = require './irc'

class IdobataMessage extends IrcMessage

  constructor: (robot) ->

    super(robot)
    @msgLabel        = "source"
    @msgType         = "html"
    @fmtLabel        = "format"
    @lineFeed        = "<br />"
    @form[@fmtLabel] = @msgType
    @infoFile        = process.env.HUBOT_IRC_INFO

  bold: (str) ->
    "<b>" + str + "</b>"

  url: (title, url) ->
    "<a href='" + u_str + "' target='_blank'>" + t_str + "</a>"

  underline: (str) ->
    "<b>" + str + "</b>"

  send: (target, msg) ->
    unless @infoFile
      console.log "#{@prefix}: Please set the value at HUBOT_IRC_INFO."
      return

    unless @infoFlag
      @info     = @readJson @infoFile, @prefix
      @infoFlag = true

    request.post
      url: taget
      headers: @info['header']
      form: @form
    , (err, response, body) ->
      console.log "err: #{err}" if err?

module.exports = IdobataMessage
