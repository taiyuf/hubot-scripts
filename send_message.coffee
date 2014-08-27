# Description:
#   Send message to chat system.
#
# Dependencies:
#   "request":     "2.34.0"
#   "read_json":   include this repogitory
#
# Configuration:
#   HUBOT_IRC_TYPE: "irc", "http_post", "idobata", "chatwork"
#   HUBOT_IRC_HEADERS: path to headers file(json).
#   HUBOT_IRC_MSG_TYPE: if you use "http_post", set the type of message. "string" or "html". default: "string"
#   HUBOT_IRC_MSG_LABEL: if you use "http_post", set the name of form's label.
#
# HUBOT_IRC_HEADERS like this,
#
# {
#     "HEADER": "VALUE",
#     ...
# }
#
# for idobata
#
# {
#     "X-API-Token": "XXXXXXXXXXXX"
# }
#
# for chatwork
#
# {
#     ""X-ChatWorkToken": "XXXXXXXXXXXXXX"
# }
#
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
    @headersFile = process.env.HUBOT_IRC_HEADERS
    @headerFlag  = false
    @headers     = {}
    @form        = {}
    @lineFeed    = ""
    @typeFlag    = false
    @typeArray   = ["irc", "http_post", "chatwork", "idobata"]
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

    if @type == "chatwork" or @type == "idobata"
      unless @headers
        console.log "#{@prefix}: Please set the value at HUBOT_IRC_HEADERS."
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
        @msgLabel       = "source"
        @msgType        = "html"
        @fmtLabel       = "format"
        @form[@fmtLabel] = @msgType
      when "chatwork"
        @msgLabel = "body"
      when "http_post"
        @form[@fmtLabel] = @msgType

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

  sleep: (ms) ->
    start = new Date().getTime()
    wait = (Math.floor(Math.random() * 10) + 1) * ms
    continue while new Date().getTime() - start < wait

  send: (target, msg) ->

    messages = ''

    if @headersFile
      unless @headerFlag
        @headers    = @readJson @headersFile, @prefix
        @headerFlag = true

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
          @sleep 100
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
              headers: @headers
              form: @form
            , (err, response, body) ->
              console.log "err: #{err}" if err?
        when "idobata"
          # console.log("form: %j", @form)
          request.post
            url: tg
            headers: @headers
            form: @form
          , (err, response, body) ->
            console.log "err: #{err}" if err?
        when "chatwork"
          messages = encodeURIComponent "[info]#{messages}[/info]"
          uri      = "#{tg}?#{@msgLabel}=#{messages}"
          # console.log "URI: #{uri}"
          request.post
            url: uri
            headers: @headers
          , (err, response, body) ->
            console.log "err: #{err}" if err?

module.exports = SendMessage
