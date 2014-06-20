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

url         = require('url')
querystring = require('querystring')
request     = require 'request'
configFile  = process.env.JENKINS_NOTIFY_CONFIG_FILE
debug       = process.env.JENKINS_NOTIFY_DEBUG?
prefix      = '[jenkins-notify]'
SendMessage = require './send_message'

makeCommitLabel = (u, array) ->
  idx = u.indexOf "http", 0
  if idx == 0
    u.replace(".git", "") if u.match(/.git$/)
    tmp = array[1] + " (" + u + "/" + array.join("/") + ")"
    return tmp
  else
    console.log "makeCommitLabel: Not url." if debug
    return array[1]

module.exports = (robot) ->

  @sm     = new SendMessage(robot)
  conf    = @sm.readJson configFile, prefix
  headers = conf['headers']
  type    = conf['type']
  target  = conf['target']

  @sm.pushTypeSet "irc"
  @sm.pushTypeSet "http_post"
  @sm.pushTypeSet "chatwork"
  @sm.setType     type
  @sm.setHeaders  headers if headers

  unless type == "irc" or type == "http_post" or type == "chatwork"
    console.log "Please set the value of 'type' in JENKINS_NOTIFY_CONFIG_FILE."
    return

  if type == "chatwork"
    unless headers
      console.log "Please set the value of 'headers' in JENKINS_NOTIFY_CONFIG_FILE."
      return

  robot.router.post "/hubot/jenkins-notify", (req, res) ->

    console.log("data: %j", req.body) if debug
    query = querystring.parse(url.parse(req.url).query)
    res.end('')

    try
      data   = req.body
      msg    = []
      commit = makeCommitLabel(data['build']['scm']['url'], ["commit", "#{data['build']['scm']['commit']}"])

      msg.push("#{@sm.bold('[Jenkins]')}")
      msg.push("project: #{@sm.bold(data['name'])}, ")
      msg.push("repository: #{@sm.underline(encodeURI(data['build']['scm']['url']))}, ")
      msg.push("branch: #{@sm.bold(data['build']['scm']['branch'])}")
      msg.push("commit: #{@sm.bold(commit)}")
      msg.push("")

      switch data['build']['phase']
        when "STARTED"
          str = "has #{@sm.bold('STARTED')}."
        when "COMPLETED"
          switch data['build']['status']
            when "SUCCESS"
              str = "has completed and #{@sm.bold('SUCCEEDED')}."
            when "FAILURE"
              str = "has completed and #{@sm.bold('FAILED')}."
        when "FINALIZED"
          switch data['build']['status']
            when "SUCCESS"
              str = "has finalized and #{@sm.bold('SUCCEEDED')}."
            when "FAILURE"
              str = "has finalized and #{@sm.bold('FAILED')}."

      msg.push("build ##{data['build']['number']} #{str}")
      @sm.send target, msg.join("\n")

    catch error
      console.log "jenkins-notify error: #{error}. Data: #{req.body}"
      console.log error.stack

