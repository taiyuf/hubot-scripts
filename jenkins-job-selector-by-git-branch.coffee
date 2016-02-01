# Do the job selected by the branch of git on jenkins
#
# Dependencies:
#   "request":     "2.34.0"
#   "url": ""
#   "querystring": ""
#
# Configuration:
#
#   JENKINS_JOBSELECTOR_CONFIG_FILE  concfigration file path.
#   JENKISN_JOBSELECTOR_SEND_MESSAGE if you set true, send the message to chat. default is false
#
#   configuration file like this,
#
#   {
#      "GIT_URL": {
#                     "target": ["hoge", "fuga"],
#                     "auth": {"id": "hoge",
#                              "password": "fuga"},
#                     "jobs":{"branchA": "JENKIS_JOB_URL_A",
#                             "branchB": ["JENKIS_JOB_URL_A", "JENKIS_JOB_URL_B"]}
#                    }
#   }
#
#   GIT_URL: http://GITLAB/USER/MODULE
#
#   if you have an api key, JENKINS_JOB_URL is like this.
#   http://USER:USER_API_KEY@JENKINS_SERVER_URL/.../job/PROJECT_NAME/build?token=USER_API_KEY
#
#   Put http://<HUBOT_URL>:<PORT>/hubot/jenkins-jobselector to web hook at your git repository.
#
#
# Commands:
#   None
#
# URLS:
#   POST /hubot/jenkins-jobselector
#
# Authors:
#   Taiyu Fujii

url         = require('url')
querystring = require('querystring')
request     = require 'request'
configFile  = process.env.JENKINS_JOBSELECTOR_CONFIG_FILE
send_flag   = process.env.JENKINS_JOBSELECTOR_SEND_MESSAGE
debug       = process.env.JENKINS_JOBSELECTOR_DEBUG?
ircType     = process.env.HUBOT_IRC_TYPE
path        = "jenkins-jobselector"
prefix      = '[#{path}]'
SendMessage = require './send_message'

request_url = (auth, url) ->
  if auth?
    request.post
      url: url
      auth: auth
  else
    request.post
    url: url

module.exports = (robot) ->

  @sm      = new SendMessage(robot)
  conf     = @sm.readJson configFile, prefix
  git_type = ''
  git_url  = ''
  auth     = ''

  robot.router.post "/hubot/#{path}", (req, res) ->

    console.log("data: %j", req.body) if debug
    query = querystring.parse(url.parse(req.url).query)
    res.end('')

    try
      hook = req.body
    catch error
      console.log "#{prefix}: There is no hook: #{error}. Data: #{req.body}"
      console.log error.stack

    unless hook.ref?
      console.log "#{prefix}: There is no hook.ref: #{error}. Data: #{req.body}"
      return

    # URL
    if hook.repository.homepage
      # gitlab
      git_url = hook.repository.homepage
    else
      # github
      git_url = hook.repository.url

    unless git_url
      console.log "#{prefix}: Unknown git repository."
      return

    console.log "GIT_URL: #{git_url}" if debug

    # Branch
    branch = hook.ref.replace "refs/heads/", ""

    try
      if conf[git_url]['auth']?
        auth = {"user": conf[git_url]['auth']['id'], "pass": conf[git_url]['auth']['password']}
    catch
      console.log "no auth infomation." if debug

    job_url = conf[git_url]['jobs'][branch]
    if typeof(job_url) == 'object'
      for j in job_url
        request_url(auth, j)
        if ircType == "slack" and send_flag
          @sm.send conf[git_url]['target'], "", @sm.slack_attachments("","[Jenkins]: The job has started on #{@sm.bold(branch)} branch at #{git_url}.")
        else
          @sm.send conf[git_url]['target'], "[Jenkins]: The job has started on #{@sm.bold(branch)} branch at #{git_url}." if send_flag
        console.log "target_URL: #{j}" if debug

    else
      if typeof(job_url) == 'string'
        request_url(auth, job_url)
        if ircType == "slack" and send_flag
          @sm.send conf[git_url]['target'], "", @sm.slack_attachments("","[Jenkins]: The job has started on #{@sm.bold(branch)} branch at #{git_url}.")
        else
          @sm.send conf[git_url]['target'], "[Jenkins]: The job has started on #{@sm.bold(branch)} branch at #{git_url}." if send_flag
        console.log "target_URL: #{job_url}" if debug

      else
        console.log "#{prefix} unknown message type: " + typeof(msg) + "."
