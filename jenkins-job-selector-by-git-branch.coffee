# Do the job selected by the branch of git on jenkins
#
# Dependencies:
#   "request":     "2.34.0"
#   "url": ""
#   "querystring": ""
#
# Configuration:
#
#   JENKINS_JOBSELECTOR_CONFIG_FILE concfigration file path.
#
#   configuration file like this,
#
#   {
#      "GIT_URL": {
#                     "target": ["hoge", "fuga"],
#                     "auth": {"id": "hoge",
#                              "password": "fuga"},
#                     "jobs":{"branchA": "JENKIS_JOB_URL_A",
#                             "branchB": "JENKIS_JOB_URL_A"}
#                    }
#   }
#
#   Put http://<HUBOT_URL>:<PORT>/hubot/jenkins-jobselector to web hook at your git repository.
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
debug       = process.env.JENKINS_JOBSELECTOR_DEBUG?
path        = "jenkins-jobselector"
prefix      = '[#{path}]'
SendMessage = require './send_message'

module.exports = (robot) ->

  @sm      = new SendMessage(robot)
  conf     = @sm.readJson configFile, prefix
  git_type = ''
  git_url  = ''

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

    if conf[git_url]['auth']
      auth = {"user": conf[git_url]['auth']['id'], "pass": conf[git_url]['auth']['password']}

    if auth?
      request.post
        url: conf[git_url]['jobs'][branch]
        auth: auth
    else
      request.post
        url: conf[git_url]['jobs'][branch]

    console.log "target_URL: #{conf[git_url]['jobs'][branch]}" if debug

    @sm.send conf[git_url]['target'], "[Jenkins]: The job has started on #{@sm.bold(branch)} branch at #{git_url}."

