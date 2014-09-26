# Description
#   Let hubot execute shell command.
#
# Dependencies:
#   send_message: include this module
#
# Configuration:
#   CMD_CONFIG: path to configuration file
#
# You need write CMD_CONFIG file in json format like this.
#
# {
#     "TARGET1": {"ACTION1": {"command": "/path/to/cmd1 ACTION1",
#                             "user": ["foo", "bar"],
#                             "message": "/path/to/cmd1 ACTION1 is executed."}
#                 "ACTION2": {"command": "/path/to/cmd1 ACTION2",
#                             "user": ["foo"],
#                             "message": "/path/to/cmd1 ACTION2 is executed."}},
#     "TARGET2": {"ACTION1": {"command": "/path/to/cmd2 ACTION1",
#                             "user": ["foo", "bar"],
#                             "message": "/path/to/cmd2 ACTION1 is executed."}}
# }
#
# You need to execute hubot as adapter for each group chat system.
# If you use slack, you need to hubot-slack adapter.
#
# You need to let hubot user allow to execute command on your system (ex. sudo).
# Each ACTION has these properties:
#   command: the expression to execute command.
#   user:    the list of user allowed to execute the command.
#   message: the message to let hubot tell when the command executed.
#
# Commands:
#   Tell bot to order.
#   @bot cmd TARGET ACTION
#
# Author:
#   Taiyu Fujii

path        = "cmd"
SendMessage = require './send_message'
prefix      = '[cmd]'
debug       = process.env.CMD_DEBUG
configFile  = process.env.CMD_CONFIG

send_message = (room, msg) ->
  unless room
    console.log "#{prefix}: There is no room to say."

  if ircType == "slack"
    @sm.send ["#{room}"], "", @sm.slack_attachments("", msg)
  else
    @sm.send ["#{room}"], msg

exec_command = (cmd) ->
  @exec = require('child_process').exec
  @exec cmd, (error, stdout, stderr) ->
    msg.send error
    msg.send stdout
    msg.send stderr

check_privilege = (list, user) ->
  flag = false
  for l in list
    if l == user
      flag = true
  if flag == true
    return true
  else
    return false

help = (msg) ->
  msg.send "Usage: cmd TARGET ACTION."
  msg.send "Your order is not match my task list. Please check again."
  return

module.exports = (robot) ->
  @sm  = new SendMessage(robot)
  conf = @sm.readJson configFile, prefix

  robot.respond /cmd (\w+) (\w+)/i, (msg) ->

    for key,val of conf
      switch msg.match[1]
        when key
          for key2,val2 of val
            switch msg.match[2]
              when key2
                if check_privilege(val2['user'], msg.message.user.name)
                  msg.send val2['message']
                  exec_command val2['command']
                else
                  msg.send "Sorry, You are not allowed to let me order."
              else
                help msg
        else
          help msg
