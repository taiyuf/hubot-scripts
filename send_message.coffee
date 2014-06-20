# Description:
#   Post gitlab related events using gitlab hooks
#
# Dependencies:
#   "request":     "2.34.0"
# Usage:
#
# SendMessage = require './send_message'
#
# @sm  = new SendMessage(robot)
# conf = @sm.readJson configFile, prefix
# return unless conf
#
# @sm.pushTypeSet "hoge"
# @sm.pushTypeSet "huga"
# @sm.setType     "hoge"
# @sm.headers = headers if headers
#
# ...
#
# @sm.send target, message
#
# Author:
#   Taiyu Fujii

class SendMessage

  fs      = require 'fs'
  request = require 'request'

  constructor: (r) ->

    unless r
      console.log "Please set the value of \"robot\"."
      console.log "Usage: @sm = new SendMessage(robot, type)"
      return

    @robot     = r
    @type      = ''
    @typeArray = []
    @typeFlag  = false
    @headers   = {}

  _check_type: () ->

    unless @type
      console.log "Please set the value of type."
      return

    for tp in @typeArray
      console.log "type: #{tp}"
      @typeFlag = true if @type == tp

    if @typeFlag == true
      return true
    else
      console.log "SendMessage: wrong type: #{@type}"
      return false

  readJson: (file, prefix) ->

    unless prefix
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

  bold: (str) ->

    return unless @_check_type

    switch @type
      when "irc"
        "\x02" + str + "\x02"
      when "http_post"
        "<strong>" + str + "</strong>"
      when "chatwork"
        str

  url: (t_str, u_str) ->

    return unless @_check_type

    switch @type
      when "irc"
        "\x1f" + t_str + "\x1f" + "(" + u_str + ")"
      when "http_post"
        "<a href='" + u_str + "' target='_blank'>" + t_str + "</a>"
      when "chatwork"
        t_str + "(" + u_str + ")"

  underline: (str) ->

    return unless @_check_type

    switch @type
      when "irc"
        "\x1f" + str + "\x1f"
      when "http_post"
        "<u>" + str + "</u>"
      when "chatwork"
        str

  send: (target, msg) ->
    for tg in target
      switch @type
        when "irc"
          @robot.send { "room": tg }, msg
        when "http_post"
          unless @heades
            request.post
              url: tg
              form: {"source": msg}
            , (err, response, body) ->
              console.log "err: #{err}" if err?
          else
            request.post
              url: tg
              headers: @headers
              form: {"source": msg}
            , (err, response, body) ->
              console.log "err: #{err}" if err?
        when "chatwork"
          msg = encodeURIComponent "[info]#{msg}[/info]"
          uri = "#{tg}?body=#{msg}"
          request.post
            url: uri
            headers: @headers
          , (err, response, body) ->
            console.log "err: #{err}" if err?

module.exports = SendMessage
