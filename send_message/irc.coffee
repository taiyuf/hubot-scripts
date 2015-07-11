class IrcMessage

  constructor: (robot) ->

    @robot       = robot
    @fs          = require 'fs'
    @request     = require 'request'
    @querystring = require 'querystring'
    @form        = {}
    @msgLabel    = 'text'
    @lineFeed    = "\n"
    @prefix      = "[send_message]"

  bold: (str) ->
    "\x02" + str + "\x02"

  url: (title, url) ->
    "\x1f" + t_str + "\x1f" + ": " + u_str

  underline: (str) ->
    "\x1f" + str + "\x1f"

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
      data = @fs.readFileSync file, 'utf-8'
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

  send: (target, msg) ->
    @robot.send { 'room': target }, messages

module.exports = IrcMessage
