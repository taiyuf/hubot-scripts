# Notifies about Jenkins build errors via Jenkins Notification Plugin
#
# Dependencies:
#   "redis-brain"
#   "request":     "2.34.0"
#   "url": ""
#   "querystring": ""
#
# Configuration:
#
#   JENKINS_NOTIFY_CONFIG_FILE:    concfigration file path.
#   JENKINS_NOTIFY_BACK_TO_NORMAL: if this value set true, send message when the job status change (FAILURE -> SUCCESS or SUCCESS -> FAILURE).
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
#   Job Notifications
#   -> Notification Endpoints
#        Format: JSON
#        Protocol: HTTP
#        Event: All Event
#        URL: http://<HUBOT_URL>:<PORT>/hubot/jenkins-notify
#        Timeout: as you like
#
# Commands:
#   None
#
# URLS:
#   POST /hubot/jenkins-notify
#
# Authors:
#   Taiyu Fujii

url          = require('url')
querystring  = require('querystring')
request      = require 'request'
configFile   = process.env.JENKINS_NOTIFY_CONFIG_FILE
debug        = process.env.JENKINS_NOTIFY_DEBUG?
backToNormal = process.env.JENKINS_NOTIFY_BACK_TO_NORMAL
ircType      = process.env.HUBOT_IRC_TYPE
prefix       = '[jenkins-notify]'
SendMessage  = require './send_message'

makeCommitLabel = (u, array) ->

  idx = u.indexOf "http", 0

  if idx == 0
    u.replace(".git", "") if u.match(/.git$/)
    return array[1] + " (" + u + "/" + array.join("/") + ")"
  else
    console.log "#{prefix}: makeCommitLabel: Not url." if debug
    return array[1]

format_number = (n) ->
  unless n
    n = "0"

  if n < 10
    return "0" + n
  else
    return n

displayTime = (diffMs) ->
  days    = parseInt(diffMs/(24*60*60*1000), 10)
  diffMs  = diffMs - days * 24 * 60 * 60 * 1000 if days > 0
  hours   = parseInt(diffMs/(60*60*1000), 10)
  diffMs  = diffMs - hours * 60 * 60 * 1000     if hours > 0
  minutes = parseInt(diffMs/(60*1000), 10)
  diffMs  = diffMs - minutes * 60 * 1000        if minutes > 0
  seconds = parseInt(diffMs/1000, 10)
  time    = []
  if hours > 0
    time.push(format_number("#{hours}"))
  else
    time.push("00")

  if minutes > 0
    time.push(format_number("#{minutes}"))
  else
    time.push("00")
  time.push(format_number("#{seconds}"))

  result  = ""
  result  = "#{days}day, "  if days > 0 and days <= 1
  result  = "#{days}days, " if days > 1
  result  = result + time.join(":")
  return result

printStatus = (target, data, diff, commit) ->
  msg = []
  msg.push("build #{@sm.bold('#' + data['build']['number'])} has completed in #{@sm.bold(data['build']['status'])}. (#{@sm.url('details', data['build']['full_url'])})")
  msg.push("elapsed time: #{diff}");
  msg.push("")
  msg.push("project: #{@sm.bold(data['name'])}")
  msg.push("repository: #{@sm.bold(encodeURI(data['build']['scm']['url']))}")
  msg.push("branch: #{@sm.bold(data['build']['scm']['branch'])}")
  msg.push("commit: #{@sm.bold(commit)}")

  if ircType == "slack"
    title = "[Jenkins]"
    color = ''
    if data['build']['status'] == "SUCCESS"
      color = "good"
    else
      color = "danger"
    @sm.send target, '', @sm.slack_attachments(title, msg, color)
    console.log "ps: %j", @sm.slack_attachments(title, msg, color)

  else
    msg.unshift("#{@sm.bold('[Jenkins]')}")
    @sm.send target, msg

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

      robot.brain.data["#{data['name']}"] = {} unless robot.brain.data["#{data['name']}"]
      robot.brain.data["#{data['name']}"]["#{data['build']['scm']['branch']}"] = {} unless robot.brain.data["#{data['name']}"]["#{data['build']['scm']['branch']}"]
      label = robot.brain.data["#{data['name']}"]["#{data['build']['scm']['branch']}"]
      label["#{data['build']['number']}"] = {} unless label["#{data['build']['number']}"]

      try
        target = conf["#{data['build']['scm']['url']}"]['target']
      catch
        console.log "#{prefix}: No target. Please check configuration file."
        return

      switch data['build']['phase']
        when "STARTED"
          label["#{data['build']['number']}"]['startdate'] = new Date().getTime()
          robot.brain.save
        when "FINALIZED"
          startdate     = label["#{data['build']['number']}"]['startdate']
          enddate       = new Date().getTime()
          diff          = displayTime(enddate - startdate)
          currentstatus = data['build']['status']
          flag          = false
          status        = ''

          if label['status']?
            status = label['status']

          if backToNormal?
            console.log "status: #{status}, #{currentstatus}" if debug
            if currentstatus != status
              printStatus(target, data, diff, commit)

            else
              console.log "#{data['name']}:#{data['build']['scm']['branch']}:#{data['build']['number']} #{currentstatus}" if debug

          else
            printStatus(target, data, diff, commit)

          if label['status']?
            delete label['status']
          label['status'] = "#{currentstatus}"
          delete label["#{data['build']['number']}"]
          robot.brain.save

    catch error
      console.log "jenkins-notify error: #{error}. Data: #{req.body}"
      console.log error.stack
