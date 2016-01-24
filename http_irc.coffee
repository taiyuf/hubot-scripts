# # Description
#
# Simple path to have Hubot echo out anything in the message querystring for a given room.
#
# # Usage
#
# ```
# curl http://YOUR_SERVER/http_irc?room=%23foo&message=hoge
#
# curl -X POST --data-urlencode message="hoge hoge." http://YOUR_SERVER/http_irc?room\=foo
# curl -X POST --data-urlencode message="hoge hoge." -d  room=foo http://YOUR_SERVER/http_irc?room=#foo
# ```
#
path        = "/http_irc"
querystring = require 'querystring'
SendMessage = require './send_message'
Log         = require './log'
log         = new Log 'http_irc'
type        = process.env.HUBOT_IRC_TYPE
debug       = process.env.HUBOT_HTTP_IRC_DEBUG
api_key     = process.env.HUBOT_HTTP_IRC_API_KEY || null
allow       = process.env.HUBOT_HTTP_IRC_ALLOW   || null
deny        = process.env.HUBOT_HTTP_IRC_DENY    || null
allow_flag  = false

# Tell the message to chat system.
#
# @example
#   send_message res, '#debug', 'hello world.', query
#
# @param res   [Object] response object.
# @param room  [String] the name of chat room.
# @param msg   [String] the message content.
# @param query [String] the query.
#
send_message = (res, room, msg, query) ->
  unless room
    log.warn 'There is no room to say.'
    res.writeHead 400, {'Content-Type': 'text/plain'}
    res.end 'Error: There is no room to say.'
    return

  options = {}
  if query.color?
    options.color = query.color
  if query.icon_emoji?
    options.icon_emoji = query.icon_emoji
  if query.icon_url?
    options.icon_url = query.icon_url

  if type is "slack"
    @sm.send ["#{room}"], msg, query
  else
    @sm.send ["#{room}"], msg

  res.writeHead 200, {'Content-Type': 'text/plain'}
  res.end 'OK'

# Check the ip match the pattern.
#
# @example
#   for p in pattern
#     if match_ip remote_ip, p
#       return true
#
# @param  ip      [String] the ip.
# @param  pattern [String] the pattern of ip.
# @return         [Bool]   true or false.
#
match_ip = (ip, pattern) ->
  if pattern.match /^\d+\.\d+\.\d+\.\d+$/
    if ip is pattern
      log.debug "equal"
      return true
    else
      log.debug "not equal"
      return false

  else if pattern.match /^(\d+\.)+$/
    rexp = new RegExp "^#{pattern}"
    result = rexp.exec ip
    if result.length isnt 0
      log.debug "success"
      return true
    else
      log.debug "fail"
      return false

  else
    log.warn "invalid pattern: #{pattern}"
    return false

# Check the remote ip address which is allowed.
#
# @example
#   unless check_ip req
#     console.log "Not allowed."
#     return
#
# @param  req [Object] the request object.
# @return     [Bool]   true or false.
#
check_ip = (req) ->

  remote_ip = req.headers['x-forwarded-for'] ||
    req.connection.remoteAddress ||
    req.socket.remoteAddress ||
    req.connection.socket.remoteAddress;
  log.debug "remote_ip: #{remote_ip}"

  unless deny is null
    deny_ips  = deny.split(',')
    for ip in deny_ips
      if match_ip remote_ip, ip
        log.debug "DENY: #{remote_ip}"
        return false

  unless allow is null
    allow_ips = allow.split(',')
    for ip in allow_ips
      if match_ip remote_ip, ip
        log.debug "ALLOW: #{ip}"
        return true

# Check the api_key from header of request.
#
# @example
#   if check_api_key req
#     return true
#
# @param  req [Object] the request object.
# @return     [Bool]   true or false.
#
check_api_key = (req) ->
  if api_key is req.headers['hubot_http_irc_api_key']
    return true
  else
    log.debug "INVALID API_KEY: #{req.headers['hubot_http_irc_api_key']}"
    return false

# Check the request is valid.
#
# @example
#   if check_request req
#     return true
#
# @param  req [Object] the request object.
# @return     [Bool]   true or false.
#
check_request = (req) ->
  switch check_ip req
    when false then return false
    when true  then return true
    else return check_api_key req

#
# Main routin.
#
module.exports = (robot) ->

  @sm     = new SendMessage robot
  room    = ''
  message = ''

  # @event for GET request.
  robot.router.get "#{path}", (req, res) ->
    if check_request(req) is false
      res.writeHead 200, {'Content-Type': 'text/plain'}
      res.end 'Not allowed to access.'
      return

    query   = querystring.parse(req._parsedUrl.query)
    room    = query.room
    message = query.message
    log.debug  query, 'query: '

    send_message(res, room, message, query)

  # @event for POST request.
  robot.router.post "#{path}", (req, res) ->

    if check_request(req) is false
      res.writeHead 200, {'Content-Type': 'text/plain'}
      res.end 'Not allowed to access.'
      return

    query   = querystring.parse(req._parsedUrl.query)
    room    = query.room or ''
    message = req.body.message
    room    = req.body.room unless room
    log.debug req.body, 'req: '
    log.debug query, 'query: '
    send_message(res, room, message, req.body)
