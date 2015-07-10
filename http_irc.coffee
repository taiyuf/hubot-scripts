# Description
#   "Simple path to have Hubot echo out anything in the message querystring for a given room."
#
# Dependencies:
#   "querystring": "0.1.0"
#
# Configuration:
#   None
#
# Commands:
#   None
#
# URLs:
#   GET  /http_irc?message=<message>&room=%23<room_name>
#    or
#   POST /http_irc?room=%23<room_name>
#
# Sample:
#
#   curl http://YOUR_SERVER/http_irc?room=%23foo&message=hoge
#
#   curl -X POST --data-urlencode message="hoge hoge." http://YOUR_SERVER/http_irc?room\=foo
#   curl -X POST --data-urlencode message="hoge hoge." -d  room=foo http://YOUR_SERVER/http_irc?room=#foo
#
# Author:
#   Taiyu Fujii

path        = "/http_irc"
querystring = require 'querystring'
SendMessage = require './send_message'
prefix      = "[http_irc]"
ircType     = process.env.HUBOT_IRC_TYPE

send_message = (res, room, msg, query) ->
  # console.log "room: #{room}"
  # console.log "msg: #{message}"
  unless room
    console.log "#{prefix}: There is no room to say."
    res.writeHead 200, {'Content-Type': 'text/plain'}
    res.end 'Error: There is no room to say.'

  # console.log "query: %j", query
  options = {}
  if query.color?
    options['color'] = query.color
  if query.icon_emoji?
    options['icon_emoji'] = query.icon_emoji
  if query.icon_url?
    options['icon_url'] = query.icon_url

  if ircType == "slack"
    # @sm.send ["#{room}"], "", @sm.slack_attachments("", msg)
    @sm.send ["#{room}"], msg, query
  else
    @sm.send ["#{room}"], msg
  res.writeHead 200, {'Content-Type': 'text/plain'}
  res.end 'OK'

module.exports = (robot) ->

  @sm     = new SendMessage robot
  room    = ''
  message = ''

  robot.router.get "#{path}", (req, res) ->
    query   = querystring.parse(req._parsedUrl.query)
    room    = query.room
    message = query.message
    console.log "query: %j", query
    send_message(res, room, message, query)

  robot.router.post "#{path}", (req, res) ->
    query   = querystring.parse(req._parsedUrl.query)
    room    = query.room or ''
    message = req.body.message
    room    = req.body.room unless room
    send_message(res, room, message, req.body)

