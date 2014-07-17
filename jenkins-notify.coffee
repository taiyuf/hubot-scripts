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
#      "GIT_REPOSITORY":{"target": ["TARGET1", "TARGET2"]}
#   }
#
#   GIT_REPOSITORY: ex. ssh://GITLABUSER@GITLAB_URL/USER/PROJECT.git
#   TARGET: channel name for IRC, or end point url for other group chat services.
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
    return array[1] + " (" + u + "/" + array.join("/") + ")"
  else
    console.log "#{prefix}: makeCommitLabel: Not url." if debug
    return array[1]

module.exports = (robot) ->

  @sm     = new SendMessage(robot)
  conf    = @sm.readJson configFile, prefix
  return unless conf

  robot.router.post "/hubot/jenkins-notify", (req, res) ->

    console.log("data: %j", req.body) if debug
    query = querystring.parse(url.parse(req.url).query)
    res.end('')

    try
      data    = req.body
      msg     = []
      git_url = ''
      commit  = makeCommitLabel(data['build']['scm']['url'], ["commit", "#{data['build']['scm']['commit']}"])

      try
        target = conf["#{data['build']['scm']['url']}"]['target']
      catch
        console.log "#{prefix}: No target. Please check configuration file."
        return

      msg.push("#{@sm.bold('[Jenkins]')}")
      msg.push("project: #{@sm.bold(data['name'])}, ")
      msg.push("repository: #{@sm.bold(encodeURI(data['build']['scm']['url']))}, ")
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
      @sm.send target, msg

    catch error
      console.log "jenkins-notify error: #{error}. Data: #{req.body}"
      console.log error.stack
