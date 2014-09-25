# Description
#   ""
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
#
# Sample:
#
#
# Author:
#   Taiyu Fujii

path        = "cmd"
SendMessage = require './send_message'
prefix      = '[cmd]'
debug       = process.env.CMD_DEBUG
configFile  = process.env.CMD_CONFIG



send_message = (room, msg) ->
  # console.log "room: #{room}"
  # console.log "msg: #{message}"
  unless room
    console.log "#{prefix}: There is no room to say."

  if ircType == "slack"
    @sm.send ["#{room}"], "", @sm.slack_attachments("", msg)
  else
    @sm.send ["#{room}"], msg
  # res.writeHead 200, {'Content-Type': 'text/plain'}
  # res.end 'OK'

exec_command = (cmd) ->
  @exec = require('child_process').exec
  @exec cmd, (error, stdout, stderr) ->
    msg.send error
    msg.send stdout
    msg.send stderr

help = () ->
  return "cmd WORD1 WORD2"

module.exports = (robot) ->

  @sm = new SendMessage(robot)
  conf = @sm.readJson configFile, prefix
  console.log "conf: %j", conf if debug?

  robot.hear /cmd (\w+) (\w+)/i, (msg) ->

    console.log "1: #{msg.match[1]}, 2: #{msg.match[2]}" if debug?

    for key,val of conf
      console.log "key: #{key}"
      switch msg.match[1]
        when key
          console.log "match: #{key}"
          for key2,val2 of val
            console.log "key2: #{key2}"
            switch msg.match[2]
              when key2
                console.log "match: #{key2}"
                msg.send val2['message']
                exec_command val2['command']
              else
                msg.send help()

        else
          msg.send help()

