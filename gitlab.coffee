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
#   GITLAB_URL
#   GITLAB_AUTH_USERNAME
#   GITLAB_AUTH_PASSWORD
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
privateToken  = process.env.GITLAB_PRIVATE_TOKEN
auth_username = process.env.GITLAB_AUTH_USERNAME
auth_password = process.env.GITLAB_AUTH_PASSWORD
debug         = process.env.GITLAB_DEBUG?
prefix        = '[gitlab]'

module.exports = (robot) ->

  @sm  = new SendMessage(robot)
  conf = @sm.readJson configFile, prefix
  return unless conf

  headers = {"PRIVATE-TOKEN": privateToken}

  if auth_username and auth_password
    auth = {"user": auth_username, "pass": auth_password}

  target  = conf['target']

  makeUrl = (projectId, Id) ->
    "#{gitlabUrl}/api/v3/projects/#{projectId}"

  # getProjectInfo = (projectId, callback) ->

  #   # return unless _check_condition

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

  #   # console.log "pj: %j", pjInfo
  #   # projectInfo

  # getMergeRequestInfo = (projectId, requestId, callback) ->

  #   # return unless _check_condition

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


  # mergeRequestInfo = (projectId, requestId, callback) ->

  #   mq_flag = false
  #   if privateToken and gitlabUrl
  #     mq_flag =  true

  #   if mq_flag
  #     getProjectInfo projectInfo, (pjInfo) ->
        
            

  handler = (mode, req, res) ->

    console.log("hook: %j", req.body) if debug
    query = querystring.parse(url.parse(req.url).query)
    hook  = req.body

    robot.brain.data[gitlabUrl] = {} unless robot.brain.data[gitlabUrl]?
    brain = robot.brain.data[gitlabUrl]

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
        # if the ref before the commit is 00000, this is a new branch
        if /^0+$/.test(hook.before)
          branch = hook.ref.split("/")[2..].join("/")
          message.push("#{@sm.bold(hook.user_name)} pushed a new branch (#{@sm.bold(branch)}) to #{@sm.bold(hook.repository.name)} (#{@sm.underline(hook.repository.homepage)})")
        else
          if hook.ref
            # push event
            branch     = hook.ref.split("/")[2..].join("/")
            indent     = "    "
            compareUrl = "#{hook.repository.homepage}/compare/#{hook.before.substr(0,9)}...#{hook.after.substr(0,9)}"

            message.push("#{@sm.bold(hook.user_name)} pushed #{@sm.bold(hook.total_commits_count)} commits to #{@sm.bold(branch)} in #{@sm.bold(hook.repository.name)}")
            message.push("#{@sm.url('compare', compareUrl)}")

            for li in @sm.list(hook.commits)
              message.push(li)

            # save data.
            namespace = hook.repository.homepage.replace(gitlabUrl + "/", "")

            console.log "brain: %j", brain if debug

            brain['user']       = {} unless brain['user']
            brain['repository'] = {} unless brain['repository']
            brain['repository'][hook.project_id] = {} unless brain['repository'][hook.project_id]

            brain['user'][hook.user_id] = hook.user_name unless brain['user'][hook.user_id]?
            brain['repository'][hook.project_id]['namespace'] = namespace unless brain['repository'][hook.project_id]['namespace']
            brain['repository'][hook.project_id]['url'] = hook.repository.homepage unless brain['repository'][hook.project_id]['url']

            robot.brain.save

          else
            if hook.object_kind
              switch hook.object_kind
                when "merge_request"
                  # merge request
                  if brain['repository'][hook.object_attributes.target_project_id]?['namespace']? and brain['repository'][hook.object_attributes.target_project_id]?['url']? and brain['user'][hook.object_attributes.author_id]?
                    mqUrl = @sm.url("#{brain['repository'][hook.object_attributes.target_project_id]['namespace']}##{hook.object_attributes.iid}", "#{brain['repository'][hook.object_attributes.target_project_id]['url']}")
                    message.push("#{@sm.bold(brain['user'][hook.object_attributes.author_id] + ' ' + hook.object_attributes.state) + ' merge request ' + mqUrl}")
                    message.push("#{@sm.bold(hook.object_attributes.title)}")
                    message.push("#{hook.object_attributes.description}")

                  else
                    message.push("Merge request has #{@sm.bold(hook.object_attributes.state)}. ")
                    message.push("Merge request ID: #{@sm.bold(hook.object_attributes.id)}")
                    message.push("Branch: #{@sm.bold(hook.object_attributes.source_branch)} -> #{@sm.bold(hook.object_attributes.target_branch)}")
                    message.push("State: #{hook.object_attributes.state}")
                    message.push("Title: #{@sm.bold(hook.object_attributes.title)}")
                    message.push("Description: #{@sm.bold(hook.object_attributes.description)}")

        @sm.send target, message

  robot.router.post "/gitlab/system", (req, res) ->
    handler "system", req, res
    res.end ""

  robot.router.post "/gitlab/web", (req, res) ->
    handler "web", req, res
    res.end ""

