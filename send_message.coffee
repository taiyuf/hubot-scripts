# Description:
#   Send message to chat system.
#
# Dependencies:
#   "request":     "2.34.0"
#   "read_json":   included in this repogitory
#
# Configuration:
#   HUBOT_IRC_TYPE: "irc", "http_post", "idobata", "chatwork"
#   HUBOT_IRC_MSG_TYPE: if you use "http_post", set the type of message. "string" or "html". default: "string"
#   HUBOT_IRC_MSG_LABEL: if you use "http_post", set the name of form's label.
#   HUBOT_IRC_INFO: path to headers file(json).
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
# {
#     "team_url": "hoge.slack.com",      # required
#     "token: {"#channel1": "hogehoge",  # required
#              "#channel2": "fugafuga"},
#     "username": "hubot",               # optional. default is "hubot"
#     "icon_emoji": ":ghost:"            # optional
# }
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

  fs       = require 'fs'
  request  = require 'request'

  constructor: (robot) ->

    @robot       = robot
    @type        = process.env.HUBOT_IRC_TYPE
    @msgLabel    = process.env.HUBOT_IRC_MSG_LABEL
    @msgType     = process.env.HUBOT_IRC_MSG_TYPE
    @fmtLabel    = process.env.HUBOT_IRC_FMT_LABEL
    @infoFile    = process.env.HUBOT_IRC_INFO
    @info        = {}
    @infoFlag  = false
    @form        = {}
    @lineFeed    = ""
    @typeFlag    = false
    @typeArray   = ["irc", "http_post", "chatwork", "idobata", "slack"]
    @prefix      = "[send_message]"
    @maxLength   = 128

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

    if @type == "chatwork" or @type == "idobata" or @type == "slack"
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
    unless @msgType
      @msgType = "string"

    switch @type
      when "idobata"
        @msgLabel        = "source"
        @msgType         = "html"
        @fmtLabel        = "format"
        @form[@fmtLabel] = @msgType
      when "chatwork"
        @msgLabel = "body"
      when "http_post"
        @form[@fmtLabel] = @msgType
      when "slack"
        @msgLabel = "text"
        @fmtLabel = "payload"

    if @msgType == "html"
      @lineFeed = "<br />"
    else
      @lineFeed = "\n"

  readJson: (file, prefix) ->

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
    # return {fallback: 'test', fields: fields, color: color}

  # slackJenkinsResults: (result) ->

  makeMarkdownList: (commits) ->
    array = ['']
    for cs in commits
      cstr = cs.message.replace /\n/g, @lineFeed
      array.push('* ' + @url(cs.id, cs.url))

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
      if @type == 'irc'
        # msg.replace(/<br>/g, @lineFeed).replace(/<br \/>/g, @lineFeed).replace(/<("[^"]*"|'[^']*'|[^'">])*>/g, '').replace(/^$/g, '').replace(/^#{@lineFeed}$/g, '')[0..64] + '....'
        ''
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
      # else
      #   console.log "unknown error on slack_attachment: #{msg}, type: " + typeof msg

    return [{fallback: message, fields: [{title: title, value: message}], color: color, mrkdwn_in: ["fallback", "fields"]}]

  sleep: (ms) ->
    start = new Date().getTime()
    wait = (Math.floor(Math.random() * 10) + 1) * ms
    continue while new Date().getTime() - start < wait

  send: (target, msg, attachments) ->

    messages = ''

    if @infoFile
      unless @infoFlag
        @info    = @readJson @infoFile, @prefix
        @infoFlag = true

    # message
    if typeof(msg) == 'object'
      messages = msg.join(@lineFeed)
    else
      if typeof(msg) == 'string'
        messages = msg
      else
        console.log "#{@prefix} unknown message type: " + typeof(msg) + "."

    @form[@msgLabel] = messages

    # main
    for tg in target
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
          # console.log("form: %j", @form)
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
          if @info['username']?
            @form['username'] = @info['username']
          else
            @form['username'] = 'hubot'

          if @info['icon_emoji']?
            @form['icon_emoji'] = @info['icon_emoji']

          @form['channel'] = tg
          # @form['mrkdwn']  = "true"
          uri = 'https://' + @info['team_url'] + '/services/hooks/incoming-webhook?token=' + @info['token'][tg]

          if attachments? or attachments != false
            @form['attachments'] = attachments
            attachments = false

          json = JSON.stringify @form
          # console.log "uri:" + uri
          # console.log "form: %j", json
          request.post
            url: uri
            form: {payload: json}
          , (err, response, body) ->
            console.log "err: #{err}" if err?

module.exports = SendMessage
