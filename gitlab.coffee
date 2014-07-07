# Description:
#   Post gitlab related events using gitlab hooks
#
# Dependencies:
#   "url" :        ""
#   "querystring": ""
#   "request":     "2.34.0"
#
# Configuration:
#   GITLAB_CONFIG_FILE: the path to configuration file.
#   GITLAB_URL        : web site url of gitlab.
#
#   configuration file like below,
#
#   {
#        "target": ["#hoge"]
#    }
#
#   Put http://<HUBOT_URL>:<PORT>/gitlab/system as your system hook
#   Put http://<HUBOT_URL>:<PORT>/gitlab/web as your web hook (per repository)
#
# Commands:
#   None
#
# URLS:
#   /gitlab/system
#   /gitlab/web
#
# TODO:
#   - merge request events
#   - tag push events
#   - issues events
#
# Author:
#   Taiyu Fujii

url          = require 'url'
querystring  = require 'querystring'
request      = require 'request'
SendMessage  = require './send_message'

configFile    = process.env.GITLAB_CONFIG_FILE
gitlabUrl     = process.env.GITLAB_URL
# privateToken  = process.env.GITLAB_PRIVATE_TOKEN
# auth_username = process.env.GITLAB_AUTH_USERNAME
# auth_password = process.env.GITLAB_AUTH_PASSWORD
debug         = process.env.GITLAB_DEBUG?
prefix        = '[gitlab]'

module.exports = (robot) ->

  @sm  = new SendMessage(robot)
  conf = @sm.readJson configFile, prefix
  return unless conf

  robot.brain.data[gitlabUrl] = {} unless robot.brain.data[gitlabUrl]?
  target = conf['target']
  brain  = robot.brain.data[gitlabUrl]

  initializeBrain = (hook) ->
    console.log "brain: %j", brain if debug

    brain['user']       = {} unless brain['user']
    brain['repository'] = {} unless brain['repository']
    brain['repository'][hook.project_id] = {} unless brain['repository'][hook.project_id]

  makeObjectKindMessage = (hook) ->

    word1 = ''
    word2 = ''
    pName = ''
    msg   = []

    initializeBrain hook

    switch hook.object_kind
      when "merge_request"
        word1 = ' merge request '
        word2 = 'Merge request'
        pName = hook.object_attributes.target_project_id
      when "issue"
        word1 = ' issue '
        word2 = 'Issue'
        pName = hook.object_attributes.project_id

    if brain['repository'][pName]?['namespace']? and brain['repository'][pName]?['url']? and brain['user'][hook.object_attributes.author_id]?

      mqUrl = @sm.url("#{brain['repository'][pName]['namespace']}##{hook.object_attributes.iid}", "#{brain['repository'][pName]['url']}")

      msg.push("#{@sm.bold(brain['user'][hook.object_attributes.author_id] + ' ' + hook.object_attributes.state) + word1 + mqUrl}")
      msg.push("#{@sm.bold(hook.object_attributes.title)}")
      msg.push("#{hook.object_attributes.description}")

    else
      msg.push("#{word2} has #{@sm.bold(hook.object_attributes.state)}. ")
      msg.push("#{word2} ID: #{@sm.bold(hook.object_attributes.id)}")
      msg.push("Branch: #{@sm.bold(hook.object_attributes.source_branch)} -> #{@sm.bold(hook.object_attributes.target_branch)}") if hook.object_kind == 'merge_request'
      msg.push("State: #{hook.object_attributes.state}")
      msg.push("Title: #{@sm.bold(hook.object_attributes.title)}")
      msg.push("Description: #{@sm.bold(hook.object_attributes.description)}")
    msg

  saveInfo = (hook) ->

    initializeBrain hook
    namespace = hook.repository.homepage.replace(gitlabUrl + "/", "")

    brain['user'][hook.user_id] = hook.user_name unless brain['user'][hook.user_id]?
    brain['repository'][hook.project_id]['namespace'] = namespace unless brain['repository'][hook.project_id]['namespace']
    brain['repository'][hook.project_id]['url'] = hook.repository.homepage unless brain['repository'][hook.project_id]['url']

    robot.brain.save

  # headers = {"PRIVATE-TOKEN": privateToken}

  # if auth_username and auth_password
  #   auth = {"user": auth_username, "pass": auth_password}


  # makeUrl = (projectId, Id) ->
  #   "#{gitlabUrl}/api/v3/projects/#{projectId}"

  # getProjectInfo = (projectId, callback) ->

  #   pjInfo = {}
  #   info        = {"url": makeUrl(projectId), "headers": headers}
  #   info['auth'] = auth if auth?

  #   request.get info, (err, response, body) ->
  #     console.log("bodyP: %j", body) if debug
  #     console.log "err: #{err}" if err?

  #     pjInfo['url']       = body['web_url']
  #     pjInfo['name']      = body['name']
  #     pjInfo['public']    = body['public']
  #     pjInfo['namespace'] = body['namespace']
  #     pjInfo['path']      = body['path']

  #     callback pjInfo

  # getMergeRequestInfo = (projectId, requestId, callback) ->

  #   mqInfo    = {}
  #   info      = {"url": "#{makeUrl(projectId)}/merge_request/#{requestId}", "headers": headers}
  #   info['auth'] = auth if auth?

  #   request.get info, (err, response, body) ->
  #     console.log("bodyM: %j", body) if debug
  #     console.log "err: #{err}" if err?

  #     mqInfo['title']         = body['title']
  #     mqInfo['description']   = body['description']
  #     mqInfo['state']         = body['state']
  #     mqInfo['source_branch'] = body['source_branch']
  #     mqInfo['target_branch'] = body['target_branch']
  #     mqInfo['author_name']   = body['author']['name']

  #     callback mqInfo

  handler = (mode, req, res) ->

    console.log("hook: %j", req.body) if debug
    query = querystring.parse(url.parse(req.url).query)
    hook  = req.body

    switch mode
      when "system"
        switch hook.event_name
          when "project_create"
            @sm.send target, "Yay! New gitlab project #{@sm.bold(hook.name)} created by #{@sm.bold(hook.owner_name)} (#{@sm.bold(hook.owner_email)})"
          when "project_destroy"
            @sm.send target, "Oh no! #{@sm.bold(hook.owner_name)} (#{@sm.bold(hook.owner_email)}) deleted the #{@sm.bold(hook.name)} project"
          when "user_add_to_team"
            @sm.send target, "#{@sm.bold(hook.project_access)} access granted to #{@sm.bold(hook.user_name)} (#{@sm.bold(hook.user_email)}) on #{@sm.bold(hook.project_name)} project"
          when "user_remove_from_team"
            @sm.send target, "#{@sm.bold(hook.project_access)} access revoked from #{@sm.bold(hook.user_name)} (#{@sm.bold(hook.user_email)}) on #{@sm.bold(hook.project_name)} project"
          when "user_create"
            @sm.send target, "Please welcome #{@sm.bold(hook.name)} (#{@sm.bold(hook.email)}) to Gitlab!"
          when "user_destroy"
            @sm.send target, "We will be missing #{@sm.bold(hook.name)} (#{@sm.bold(hook.email)}) on Gitlab"

      when "web"
        message = []
        if hook.ref
          value = hook.ref.split("/")[2..].join("/")
          label = hook.ref.split("/")[1]
          if /^0+$/.test(hook.before)
            # this is a new branch or tag.
            message.push("#{@sm.bold(hook.user_name)} pushed a new #{label} (#{@sm.bold(value)}) to #{@sm.bold(hook.repository.name)}")
            message.push("#{@sm.underline(hook.repository.homepage + '/commit/' + hook.after)}")
          else
            if /^0+$/.test(hook.after)
              # branch or tag is deleted.
              message.push("#{@sm.bold(hook.user_name)} deleted #{label} (#{@sm.bold(value)}) to #{@sm.bold(hook.repository.name)}")
              message.push("#{@sm.underline(hook.repository.homepage + '/commit/' + hook.before)}")
            else
              # normal push event.
              branch     = hook.ref.split("/")[2..].join("/")
              indent     = "    "
              compareUrl = "#{hook.repository.homepage}/compare/#{hook.before.substr(0,9)}...#{hook.after.substr(0,9)}"

              message.push("#{@sm.bold(hook.user_name)} pushed #{@sm.bold(hook.total_commits_count)} commits to #{@sm.bold(branch)} in #{@sm.bold(hook.repository.name)}")
              message.push("#{@sm.url('compare', compareUrl)}")

              for li in @sm.list(hook.commits)
                message.push(li)

              saveInfo hook
        else
          if hook.object_kind
            message = makeObjectKindMessage(hook)
          else
            console.log "Unknown message type."
            console.log "hook: %j", hook

        @sm.send target, message

  robot.router.post "/gitlab/system", (req, res) ->
    handler "system", req, res
    res.end ""

  robot.router.post "/gitlab/web", (req, res) ->
    handler "web", req, res
    res.end ""

