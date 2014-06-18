# Notifies about Jenkins build errors via Jenkins Notification Plugin
#
# Dependencies:
#   "request":     "2.34.0"
#   "url": ""
#   "querystring": ""
#
# Configuration:
#
#   JENKINS_NOTIFY_CONFIG_FILE concfigration file path.
#
#   configuration file like this,
#
#   {
#      "type": "irc",
#      "target": ["hoge", "fuga"],
#      "headers": {"foo": "bar", ... }  # optional
#   }
#
#   Put http://<HUBOT_URL>:<PORT>/hubot/jenkins-notify to your Jenkins
#   Notification config. See here: https://wiki.jenkins-ci.org/display/JENKINS/Notification+Plugin
#
# Commands:
#   None
#
# URLS:
#   POST /hubot/jenkins-notify
#
# Authors:
#   Taiyu Fujii

fs          = require 'fs'
path        = require 'path'
url         = require('url')
querystring = require('querystring')
request     = require 'request'
configFile  = process.env.JENKINS_NOTIFY_CONFIG_FILE
debug       = process.env.JENKINS_NOTIFY_DEBUG?
prefix      = '[jenkins-notify]'

makeCommitLabel = (u, array) ->
  idx = u.indexOf "http", 0
  if idx == 0
    u.replace(".git", "") if u.match(/.git$/)
    tmp = array[1] + " (" + u + "/" + array.join("/") + ")"
    return tmp
  else
    console.log "makeCommitLabel: Not url." if debug
    return array[1]

read_json = (file) ->
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

dst     = read_json configFile
headers = dst['headers']
type    = dst['type']

unless type == "irc" or type == "http_post" or type == "chatwork"
  console.log "Please set the value of 'type' in NJ_CONFIG_FILE."
  return

if type == "chatwork"
  unless headers
    console.log "Please set the value of 'headers' in NJ_CONFIG_FILE."
    return

module.exports = (robot) ->

  send_msg = (type, target, msg) ->
    for t in target
      switch type
        when "irc"
          robot.send { "room": t }, msg
        when "http_post"
          if headers
            request.post
              url: t
              headers: headers
              form: {"source": msg}
            , (err, response, body) ->
              console.log "err: #{err}" if err?
          else
            request.post
              url: t
              form: {"source": msg}
            , (err, response, body) ->
              console.log "err: #{err}" if err?
        when "chatwork"
          msg = encodeURIComponent "[info]#{msg}[/info]"
          uri = "#{t}?body=#{msg}"
          request.post
            url: uri
            headers: headers
          , (err, response, body) ->
            console.log "err: #{err}" if err?

  robot.router.post "/hubot/jenkins-notify", (req, res) ->

    console.log("data: %j", req.body) if debug
    query = querystring.parse(url.parse(req.url).query)
    res.end('')

    try
      data   = req.body
      msg    = []
      commit = makeCommitLabel(data['build']['scm']['url'], ["commit", "#{data['build']['scm']['commit']}"])
      msg.push("[Jenkins]")
      msg.push("project: #{data['name']}, ")
      msg.push("repository: #{encodeURI(data['build']['scm']['url'])}, ")
      msg.push("branch: #{data['build']['scm']['branch']}")
      msg.push("commit: #{commit}")
      msg.push("")

      switch data['build']['phase']
        when "STARTED"
          str = "has started."
        when "COMPLETED"
          switch data['build']['status']
            when "SUCCESS"
              str = "has completed and SUCCEEDED."
            when "FAILURE"
              str = "has completed and FAILED."
        when "FINALIZED"
          switch data['build']['status']
            when "SUCCESS"
              str = "has finalized and SUCCEEDED."
            when "FAILURE"
              str = "has finalized and FAILED."

      msg.push("build ##{data['build']['number']} #{str}")
      send_msg type, dst['target'], msg.join("\n")

    catch error
      console.log "jenkins-notify error: #{error}. Data: #{req.body}"
      console.log error.stack

