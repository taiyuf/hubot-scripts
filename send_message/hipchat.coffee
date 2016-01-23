IrcMessage = require './irc'

class HipchatMessage extends IrcMessage

  constructor: (robot) ->

    super(robot)
    @msgLabel = "message"
    @fmtLabel = "message_format"
    @infoFile = process.env.HUBOT_IRC_INFO

  bold: (str) ->
    str

  url: (title, url) ->
    "#{t_str}: #{u_str}"

  underline: (str) ->
    str

  send: (target, msg) ->

    unless @infoFile
      @log.warn 'Please set the value at HUBOT_IRC_INFO.'
      return

    unless @infoFlag
      @info     = @readJson @infoFile, @prefix
      @infoFlag = true

    room_id    = @info['target'][target]['id']
    room_token = @info['target'][target]['token']
    uri        = "https://api.hipchat.com/v2/room/#{room_id}/notification?auth_token=#{room_token}"

    try
      color = @info['target'][target]['color']
    catch
      try
        color = @info.color
      catch
        color = 'blue'
    if option?
      color = option

    form            = {}
    form.color      = color
    form[@fmtLabel] = 'text'
    form[@msgLabel] = @msg_filter msg

    request.post
      url: uri
      headers: "Content-Type": "application/json"
      json: true
      body: JSON.stringify form
    , (err, response, body) ->
      @log.warn err, "err: " if err

module.exports = HipchatMessage
