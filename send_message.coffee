# # Description:
#
# Send message to chat system.
#
# # Configuration
#
#   HUBOT_IRC_TYPE: "irc", "http_post", "idobata", "chatwork", "hipchat"
#   HUBOT_IRC_MSG_TYPE: if you use "http_post", set the type of message. "string" or "html". default: "string"
#   HUBOT_IRC_MSG_LABEL: if you use "http_post", set the name of form's label.
#   HUBOT_IRC_INFO: path to group chat system's  infomation file(json).
#
# HUBOT_IRC_INFO like this,
#
# ```
# {
#     "HEADER": "VALUE",
#     ...
# }
#
# for idobata
#
# {
#     "header": {"X-API-Token": "XXXXXXXXXXXX"}
# }
#
# for chatwork
#
# {
#     "header": {"X-ChatWorkToken": "XXXXXXXXXXXXXX"}
# }
# ```
#
# for slack
#
# old webhook style.
#
# ```
# {
#     "team_url": "hoge.slack.com",      # required
#     "token: {"#channel1": "hogehoge",  # required
#              "#channel2": "fugafuga"},
#     "username": "hubot",               # optional. default is "hubot"
#     "icon_emoji": ":ghost:"            # optional
# }
# ```
#
# new webhook style.
#
# ```
# {
#     "webhook_url": "https://hooks.slack.com/services/.....",  # required
#     "username": "hubot",                                      # optional. default is "hubot"
#     "icon_emoji": ":ghost:"                                   # optional
# }
# ```
#
# for hipchat
#
# ```
# {
#         "target": {"ROOM_NAME": {"id": ROOM_ID,
#                                  "token": "ROOM_TOKEN",
#                                  "color": "green"}
#                   },
#         "color": "blue"  # default back ground color
# }
# ```
#
# ROOM_ID, ROOM_TOKEN are Group Admin -> Rooms -> API ID , Room Notification Tokens.
# "color" is allowed in "yellow", "red", "green", "purple", "gray", or "random".
#
# Usage:
#
# ```
# SendMessage = require './send_message'
#
# @sm  = new SendMessage(robot)
# conf = @sm.readJson configFile, prefix
# return unless conf
#
# ...
#
# @sm.send target(Array), message(Array or String)
# ```
#
class SendMessage

  fs              = require 'fs'
  request         = require 'request'
  querystring     = require 'querystring'
  IrcMessage      = require './send_message/irc'
  HttpPostMessage = require './send_message/http_post'
  IdobataMessage  = require './send_message/idobata'
  ChatworkMessage = require './send_message/chatwork'
  SlackMessage    = require './send_message/slack'
  HipchatMessage  = require './send_message/hipchat'
  Log             = require './log'
  log             = new Log 'send_message'

  constructor: (robot) ->

    @robot    = robot
    @type     = process.env.HUBOT_IRC_TYPE
    @msgLabel = process.env.HUBOT_IRC_MSG_LABEL
    @msgType  = process.env.HUBOT_IRC_MSG_TYPE
    @fmtLabel = process.env.HUBOT_IRC_FMT_LABEL
    @infoFile = process.env.HUBOT_IRC_INFO
    @maxLengt = 128

    @irc      = new IrcMessage robot
    @http_pos = new HttpPostMessage robot
    @idobata  = new IdobataMessage robot
    @chatwork = new ChatworkMessage robot
    @slack    = new SlackMessage robot
    @hipchat  = new HipchatMessage robot

    # check
    unless @type
      log.warn 'Please set the value of type at HUBOT_IRC_TYPE.'
      return

    unless robot
      log.warn 'Please set the value of "robot".'
      log.warn 'Usage: @sm = new SendMessage(robot)'
      return

  readJson: (file, prefix) ->
    @irc.readJson file, prefix

  makeHtmlList: (commits) ->
    array   = []
    listmsg = "<ul>"

    for cs in commits
      cstr    = cs.message.replace /\n/g, @lineFeed
      cid     = @url(cs.id, cs.url)
      listmsg = "#{listmsg}<li>#{cid}#{@lineFeed}"
      listmsg = "#{listmsg}#{cstr}</li>"

    listmsg = "#{listmsg}</ul>"
    array.push listmsg

    return array

  slackCommitMessage: (commits, color) ->
    fallback = []
    fields   = []
    unless color?
      color = "#aaaaaa"

    for cs in commits
      cstr = cs.message.replace /\n/g, @lineFeed
      array = []
      field = {}
      array.push @url('link', cs.url)
      array.push cstr
      array.push @lineFeed
      array.push @lineFeed

      fallback.push array.join(@lineFeed)

      field.title = "* #{cs.id}"
      field.value = array.join @lineFeed

      fields.push field

    return {fallback: fallback.join(@lineFeed), fields: fields, color: color, mrkdwn_in: ["fallback", "fields"]}

  makeMarkdownList: (commits) ->
    array = []
    for cs in commits
      cstr = cs.message.replace /\n/g, @lineFeed
      array.push "* #{@url(cs.id, cs.url)}"

    return array

  makeStrList: (commits) ->
    array  = []
    indent = "    "

    for cs in commits
      cstr = cs.message.replace /\n/g, "#{@lineFeed}#{indent}"
      array.push "  - #{cs.id}"
      array.push "#{indent}#{cstr}"
      array.push "#{indent}#{cs.url}"

    return array

  list: (commits) ->

    commitsArray = []

    switch @type
      when "irc"
        commitsArray   = @makeStrList commits
      when "chatwork"
        commitsArray   = @makeStrList commits
      when "http_post"
        if @msgType == "html"
          commitsArray = @makeHtmlList commits
        else
          commitsArray = @makeStrList  commits
      when "idobata"
        commitsArray   = @makeHtmlList commits
      when "slack"
        commitsArray   = @makeMarkdownList commits

    return commitsArray

  htmlFilter: (msg) ->
    if @msgType == 'html'
      msg
    else
      msg
      .replace(/<br>/g, @lineFeed)
      .replace(/<br \/>/g, @lineFeed)
      .replace(/<("[^"]*"|'[^']*'|[^'">])*>/g, '')
      .replace(/^$/g, '')
      .replace(/^#{@lineFeed}$/g, '')

  slack_attachments: (title, msg, color) ->
    message = ""
    unless color?
      color = "#aaaaaa"

    if typeof msg == "object"
      message = msg.join @lineFeed
    else
      if typeof msg == "string"
        message = msg
      else
        log.warn "msg error #{msg}"

    return [{fallback: message, fields: [{title: title, value: message}], color: color, mrkdwn_in: ["fallback", "fields"]}]

  sleep: (ms) ->
    start = new Date().getTime()
    wait  = (Math.floor(Math.random() * 10) + 1) * ms
    continue while new Date().getTime() - start < wait

  send: (target, msg, option) ->

    messages = ''

    if typeof(target) is 'object'
      targets = target
    else
      targets = []
      targets.push target

    # main
    for tg in targets
      switch @type
        when "irc"
          @irc.send tg, msg

        when "http_post"
          @http_post.send tg, msg

        when "idobata"
          @idobata.send tg, msg

        when "chatwork"
          @chatwork.send tg, msg

        when "slack"
          @slack.send tg, msg, option

        when "hipchat"
          @hipchat.send tg, msg

module.exports = SendMessage
