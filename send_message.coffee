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
#
# HUBOT_IRC_HEADERS like this,
#
# {
#     "HEADER": "VALUE",
#     ...
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
# @sm.headers = headers if headers
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

  constructor: (r) ->

    @type = process.env.HUBOT_IRC_TYPE

    unless @type
      console.log "Please set the value of 'type' in HUBOT_IRC_TYPE."
      return

    unless r
      console.log "Please set the value of \"robot\"."
      console.log "Usage: @sm = new SendMessage(robot)"
      return

    @robot       = r
    @typeArray   = ["irc", "http_post", "chatwork", "idobata"]
    @typeFlag    = false
    @headers     = {}
    @msgLabel    = "body"
    @msgType     = process.env.HUBOT_IRC_MSG_TYPE
    @lineFeed    = ""
    @headersFile = process.env.HUBOT_IRC_HEADERS

    return unless @_check_type

    if @headersFile
      @headers = @readJson @headersFile, '[send_message]'

    if @type == "chatwork" or @type == "idobata"
      unless @headers
        console.log "Please set the value of 'headers' in HUBOT_IRC_HEADERS."
        return

    if @type == "http_post"
      unless @msgType
        console.log "Please set the value of HUBOT_IRC_MSG_TYPE."
        return
    else
      unless @msgType
        @setMsgType "string"

    if @type == "idobata"
      @setMsgLabel "source"
      @setMsgType  "html"

    @setLineFeed()

  _check_type: () ->

    unless @type
      console.log "Please set the value of type."
      return

    for tp in @typeArray
      @typeFlag = true if @type == tp

    if @typeFlag == true
      return true
    else
      console.log "SendMessage: wrong type: #{@type}"
      return false

  readJson: (file, prefix) ->

    unless file
      console.log "Please set the value of \"file\"."
      return

    unless prefix
      console.log "Error occured in loading the file \"#{file}\"."
      console.log "Please set the value of \"prefix\"."
      return

    try
      data = fs.readFileSync file, 'utf-8'
      try
        json = JSON.parse(data)
        console.log "#{prefix} success to load file: #{file}."
        return json
      catch
        console.log "#{prefix} Error on parsing the json file: #{file}"
        return
    catch
      console.log "#{prefix} Error on reading the json file: #{file}"
      return


  pushTypeSet: (t) ->
    @typeArray.push t

  setType: (t) ->
    @type = t

  setHeaders: (h) ->
    @headers = h

  setMsgLabel: (l) ->
    @msgLabel = l

  setLineFeed: (lf) ->
    @lineFeed = lf

  setMsgType: (smt) ->
    @msgType  = smt

  setLineFeed: ()->
    if @msgType == "html"
      @lineFeed = "<br />"
    else
      @lineFeed = "\n"

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

  send: (target, msg) ->

    form = {}
    messages = ''

    if typeof(msg) == 'object'
      messages = msg.join(@lineFeed)
    else
      if typeof(msg) == 'string'
        messages = msg
      else
        console.log "#{@prefix} unknown message type: " + typeof(msg) + "."

    form["#{@msgLabel}"] = messages

    if @type == "http_post"
      unless @msgLabel
        console.log "Please set \"msgLabel\"."
        return

    if @type == "idobata"
      unless @msgLabel
        console.log "Please set \"msgLabel\"."
        return
      form['format'] = 'html'

    for tg in target
      switch @type
        when "irc"
          @robot.send { "room": tg }, messages
        when "http_post"
          unless @heades
            request.post
              url: tg
              form: form
            , (err, response, body) ->
              console.log "err: #{err}" if err?
          else
            request.post
              url: tg
              headers: @headers
              form: form
            , (err, response, body) ->
              console.log "err: #{err}" if err?
        when "idobata"
          console.log("form: %j", form)
          request.post
            url: tg
            headers: @headers
            form: form
          , (err, response, body) ->
            console.log "err: #{err}" if err?
        when "chatwork"
          messages = encodeURIComponent "[info]#{messages}[/info]"
          uri      = "#{tg}?body=#{messages}"
          request.post
            url: uri
            headers: @headers
          , (err, response, body) ->
            console.log "err: #{err}" if err?

module.exports = SendMessage
