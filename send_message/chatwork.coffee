IrcMessage = require './irc'

class ChatworkMessage extends IrcMessage

  constructor: (robot) ->

    super(robot)
    @msgLabel = "body"
    @infoFile = process.env.HUBOT_IRC_INFO

  bold: (str) ->
    str

  url: (title, url) ->
    "#{t_str}: #{u_str}"

  underline: (str) ->
    str

  send: (target, msg) ->

    messages = @msg_filter msg

    unless @infoFile
      console.log "#{@prefix}: Please set the value at HUBOT_IRC_INFO."
      return

    unless @infoFlag
      @info     = @config.get @infoFile
      @infoFlag = true

    messages = encodeURIComponent "[info]#{messages}[/info]"
    uri      = "#{target}?#{@msgLabel}=#{messages}"

    request.post
      url: uri
      headers: @info.header
    , (err, response, body) ->
      @log.debug err, "err: " if err

module.exports = ChatworkMessage
