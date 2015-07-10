# Description:
#   Send message to chat system.
#
# Dependencies:
#   "request":     "2.34.0"
#   "read_json":   included in this repogitory
#
# Configuration:
#   HUBOT_IRC_TYPE: "irc", "http_post", "idobata", "chatwork", "hipchat"
#   HUBOT_IRC_MSG_TYPE: if you use "http_post", set the type of message. "string" or "html". default: "string"
#   HUBOT_IRC_MSG_LABEL: if you use "http_post", set the name of form's label.
#   HUBOT_IRC_INFO: path to group chat system's  infomation file(json).
#
# HUBOT_IRC_INFO like this,
#
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
#
# for slack
#
# old webhook style.
#
# {
#     "team_url": "hoge.slack.com",      # required
#     "token: {"#channel1": "hogehoge",  # required
#              "#channel2": "fugafuga"},
#     "username": "hubot",               # optional. default is "hubot"
#     "icon_emoji": ":ghost:"            # optional
# }
#
# new webhook style.
#
# {
#     "webhook_url": "https://hooks.slack.com/services/.....",  # required
#     "username": "hubot",                                      # optional. default is "hubot"
#     "icon_emoji": ":ghost:"                                   # optional
# }
#
# for hipchat
#
# {
#         "target": {"ROOM_NAME": {"id": ROOM_ID,
#                                  "token": "ROOM_TOKEN",
#                                  "color": "green"}
#                   },
#         "color": "blue"  # default back ground color
# }
#
# ROOM_ID, ROOM_TOKEN are Group Admin -> Rooms -> API ID , Room Notification Tokens.
# "color" is allowed in "yellow", "red", "green", "purple", "gray", or "random".
#
# Usage:
#
# SendMessage = require './send_message'
#
# @sm  = new SendMessage(robot)
# conf = @sm.readJson configFile, prefix
# return unless conf
#
# ...
#
# @sm.send target(Array), message(Array or String)
#
# Author:
#   Taiyu Fujii

class SendMessage

  fs           = require 'fs'
  request      = require 'request'
  querystring  = require 'querystring'
  IrcMessage   = require './send_message/irc'
  SlackMessage = require './send_message/slack'

  constructor: (robot) ->

    @robot       = robot
    @type        = process.env.HUBOT_IRC_TYPE
    @msgLabel    = process.env.HUBOT_IRC_MSG_LABEL
    @msgType     = process.env.HUBOT_IRC_MSG_TYPE
    @fmtLabel    = process.env.HUBOT_IRC_FMT_LABEL
    @infoFile    = process.env.HUBOT_IRC_INFO
    @info        = {}
    @infoFlag    = false
    @form        = {}
    @lineFeed    = ""
    @typeFlag    = false
    @typeArray   = ["irc", "http_post", "chatwork", "idobata", "slack", "hipchat"]
    @prefix      = "[send_message]"
    @maxLength   = 128

    @slack = new SlackMessage

    # check
    unless @type
      console.log "#{@prefix}: Please set the value of type at HUBOT_IRC_TYPE."
      return

    unless robot
      console.log "#{@prefix}: Please set the value of \"robot\"."
      console.log "#{@prefix}: Usage: @sm = new SendMessage(robot)"
      return

    for tp in @typeArray
      @typeFlag = true if @type == tp

    unless @typeFlag
      console.log "#{@prefix}: wrong type, #{@type}"
      return

    if @type == "chatwork" or @type == "idobata" or @type == "slack" or @type == "hipchat"
      unless @info
        console.log "#{@prefix}: Please set the value at HUBOT_IRC_INFO."
        return

    if @type == "http_post"
      unless @msgType
        console.log "#{@prefix}: Please set the value at HUBOT_IRC_MSG_TYPE."
        console.log "#{@prefix}: \"string\" type has selected."
      unless @msgLabel
        console.log "#{@prefix}: Please set the value at HUBOT_IRC_MSG_LABEL."
        return

    # initialize
    switch @type
      when 'irc'
        @msgType         = "string"
      when 'idobata'
        @msgLabel        = "source"
        @msgType         = "html"
        @fmtLabel        = "format"
        @form[@fmtLabel] = @msgType
      when 'chatwork'
        @msgLabel = "body"
      when 'http_post'
        @form[@fmtLabel] = @msgType
      when 'slack'
        @msgLabel = "text"
        @fmtLabel = "payload"
      when 'hipchat'
        @msgLabel = "message"
        @fmtLabel = "message_format"
      else
        @msgType = "string"

    if @msgType == "html"
      @lineFeed = "<br />"
    else
      @lineFeed = "\n"

  readJson: (file, prefix) ->

    unless prefix
      prefix = @prefix

    unless file
      console.log "#{@prefix}: Please set the value of \"file\"."
      return

    unless prefix
      console.log "#{@prefix}: Error occured in loading the file \"#{file}\"."
      console.log "Please set the value of \"prefix\"."
      return

    try
      data = fs.readFileSync file, 'utf-8'
      try
        json = JSON.parse(data)
        console.log "#{@prefix} success to load file: #{file}."
        return json
      catch
        console.log "#{@prefix} Error on parsing the json file: #{file}"
        return
    catch
      console.log "#{@prefix} Error on reading the json file: #{file}"
      return

  bold: (str) ->

    switch @type
      when "irc"
        "\x02" + str + "\x02"
      when "http_post"
        "<strong>" + str + "</strong>"
        # "<b>" + str + "</b>"
      when "idobata"
        # "<strong>" + str + "</strong>"
        "<b>" + str + "</b>"
      when "chatwork"
        str
      when "slack"
        ' *' + str + '* '
      when "hipchat"
        str
      else
        str

  url: (t_str, u_str) ->

    switch @type
      when "irc"
        "\x1f" + t_str + "\x1f" + ": " + u_str
      when "http_post"
        "<a href='" + u_str + "' target='_blank'>" + t_str + "</a>"
      when "idobata"
        "<a href='" + u_str + "' target='_blank'>" + t_str + "</a>"
      when "chatwork"
        t_str + ": " + u_str
      when "slack"
        '<' + u_str + '|' + t_str + '>'
      when "hipchat"
        t_str + ": " + u_str
      else
        t_str + ": " + u_str

  underline: (str) ->

    switch @type
      when "irc"
        "\x1f" + str + "\x1f"
      when "http_post"
        "<u>" + str + "</u>"
      when "idobata"
        "<b>" + str + "</b>"
      when "chatwork"
        str
      when "slack"
        ' *' + str + '* '
      when "hipchat"
        str
      else
        str

  makeHtmlList: (commits) ->
    array   = []
    listmsg = "<ul>"

    for cs in commits
      cstr    = cs.message.replace /\n/g, @lineFeed
      cid     = @url(cs.id, cs.url)
      listmsg = "#{listmsg}" + "<li>" + cid + @lineFeed
      listmsg = "#{listmsg}" + cstr + "</li>"

    listmsg = "#{listmsg}" + "</ul>"
    array.push("#{listmsg}")

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
      array.push(@url('link', cs.url))
      array.push(cstr)
      array.push(@lineFeed)
      array.push(@lineFeed)

      fallback.push(array.join(@lineFeed))

      field['title'] = '* ' + cs.id
      field['value']  = array.join(@lineFeed)

      fields.push(field)

    return {fallback: fallback.join(@lineFeed), fields: fields, color: color, mrkdwn_in: ["fallback", "fields"]}

  makeMarkdownList: (commits) ->
    array = []
    for cs in commits
      cstr = cs.message.replace /\n/g, @lineFeed
      array.push('* ' + @url(cs.id, cs.url))

    return array

  makeStrList: (commits) ->
    array  = []
    indent = "    "

    for cs in commits
      cstr = cs.message.replace /\n/g, "#{@lineFeed}#{indent}"
      array.push("  - " + cs.id)
      array.push(indent + cstr)
      array.push(indent + cs.url)

    return array

  list: (commits) ->

    commitsArray = []

    switch @type
      when "irc"
        commitsArray   = @makeStrList  commits
      when "chatwork"
        commitsArray   = @makeStrList  commits
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
    # return '' if @type == 'irc'
    if @msgType == 'html'
      msg
    else
      msg.replace(/<br>/g, @lineFeed).replace(/<br \/>/g, @lineFeed).replace(/<("[^"]*"|'[^']*'|[^'">])*>/g, '').replace(/^$/g, '').replace(/^#{@lineFeed}$/g, '')

  slack_attachments: (title, msg, color) ->
    message = ""
    unless color?
      color = "#aaaaaa"

    if typeof msg == "object"
      message = msg.join(@lineFeed)
    else
      if typeof msg == "string"
        message = msg
      else
        console.log "#{@prefix}: msg error #{msg}"
            # else
      #   console.log "unknown error on slack_attachment: #{msg}, type: " + typeof msg
    # console.log "sa: #{message}"

    return [{fallback: message, fields: [{title: title, value: message}], color: color, mrkdwn_in: ["fallback", "fields"]}]

  sleep: (ms) ->
    start = new Date().getTime()
    wait  = (Math.floor(Math.random() * 10) + 1) * ms
    continue while new Date().getTime() - start < wait

  send: (target, msg, option) ->

    messages = ''

    if @infoFile
      unless @infoFlag
        @info    = @readJson @infoFile, @prefix
        @infoFlag = true

    # message
    if typeof(msg) is 'object'
      messages = msg.join(@lineFeed)
    else
      if typeof(msg) is 'string'
        messages = msg
      else
        console.log "#{@prefix} unknown message type: " + typeof(msg) + "."

    @form[@msgLabel] = messages

    if typeof(target) is 'object'
      targets = target
    else
      targets = []
      targets.push target

    # main
    for tg in targets
      switch @type
        when "irc"
          @robot.send { "room": tg }, messages

        when "http_post"
          unless @heades
            request.post
              url: tg
              form: @form
            , (err, response, body) ->
              console.log "err: #{err}" if err?
          else
            request.post
              url: tg
              headers: @info['header']
              form: @form
            , (err, response, body) ->
              console.log "err: #{err}" if err?

        when "idobata"
          request.post
            url: tg
            headers: @info['header']
            form: @form
          , (err, response, body) ->
            console.log "err: #{err}" if err?

        when "chatwork"
          messages = encodeURIComponent "[info]#{messages}[/info]"
          uri      = "#{tg}?#{@msgLabel}=#{messages}"
          request.post
            url: uri
            headers: @info['header']
          , (err, response, body) ->
            console.log "err: #{err}" if err?

        when "slack"
          @slack.default tg, msg, option

        when "hipchat"
          room_id    = @info['target'][tg]['id']
          room_token = @info['target'][tg]['token']
          uri        = 'https://api.hipchat.com/v2/room/' + room_id + '/notification?auth_token=' + room_token

          try
            color = @info['target'][tg]['color']
          catch
            try
              color = @info['color']
            catch
              color = 'blue'
          if option?
            color = option

          form = {}
          form['color']   = color
          form[@fmtLabel] = 'text'
          form[@msgLabel] = messages

          # console.log JSON.stringify form

          request.post
            url: uri
            headers: "Content-Type": "application/json"
            json: true
            body: JSON.stringify form
          , (err, response, body) ->
            console.log "err: #{err}" if err?

module.exports = SendMessage
