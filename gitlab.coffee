# Description:
#   Post gitlab related events using gitlab hooks
#
# Dependencies:
#   "redis-brain"
#   "url" :        ""
#   "querystring": ""
#   "request":     "2.34.0"
#
# Configuration:
#   GITLAB_CONFIG_FILE: the path to configuration file.
#   GITLAB_URL: gitlab web site url. if your gitlab module's url is http://hoge.com/USER/MODULE.git, the GITLAB_URL value is http://hoge.com.
#
#   configuration file like below,
#
# IRC
#
#   {
#        "DEFAULT": {"target": ["#hoge"]},
#        "http://YOUR_GIT_WEB_SITE/USER/HOGE": {"target": ["#hoge", "#fuga"]},
#        "http://YOUR_GIT_WEB_SITE/USER/FUGA": {"target": ["#fuga"]},
#        ...,
#    }
#
# Other
#
#    {
#        "DEFAULT": {"target": ["http://...."]},
#        "http://YOUR_GIT_WEB_SITE/USER/HOGE": {"target": ["http://....", "http://...."]},
#        "http://YOUR_GIT_WEB_SITE/USER/FUGA": {"target": ["http://...."]},
#        ...,
#    }
#
#    DEFAULT: "DEFAULT" is string. hubot tell the message to this room which is not specified.

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

url         = require 'url'
querystring = require 'querystring'
request     = require 'request'
SendMessage = require './send_message'

configFile  = process.env.GITLAB_CONFIG_FILE
gitlabUrl   = process.env.GITLAB_URL
debug       = process.env.GITLAB_DEBUG?
ircType     = process.env.HUBOT_IRC_TYPE
prefix      = '[gitlab]'

# privateToken  = process.env.GITLAB_PRIVATE_TOKEN
# auth_username = process.env.GITLAB_AUTH_USERNAME
# auth_password = process.env.GITLAB_AUTH_PASSWORD

module.exports = (robot) ->

  @sm  = new SendMessage(robot)
  conf = @sm.readJson configFile, prefix
  return unless conf

  brain = robot.brain.data

  initializeBrain = (hook) ->
    brain[gitlabUrl]                                = {} unless brain[gitlabUrl]?
    brain[gitlabUrl]['user']                        = {} unless brain[gitlabUrl]['user']
    brain[gitlabUrl]['repository']                  = {} unless brain[gitlabUrl]['repository']
    brain[gitlabUrl]['repository'][hook.project_id] = {} unless brain[gitlabUrl]['repository'][hook.project_id]

  makeObjectKindMessage = (hook, url) ->

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

    if brain[gitlabUrl]['repository'][pName]?['namespace']? and brain[gitlabUrl]['repository'][pName]?['url']? and brain[gitlabUrl]['user'][hook.object_attributes.author_id]?

      mqUrl = @sm.url("#{brain[gitlabUrl]['repository'][pName]['namespace']}##{hook.object_attributes.iid}", "#{brain[gitlabUrl]['repository'][pName]['url']}")

      msg.push("#{@sm.bold(brain[gitlabUrl]['user'][hook.object_attributes.author_id] + ' ' + hook.object_attributes.state) + word1 + mqUrl}")
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

    brain[gitlabUrl]['user'][hook.user_id] = hook.user_name unless brain[gitlabUrl]['user'][hook.user_id]?
    brain[gitlabUrl]['repository'][hook.project_id]['namespace'] = namespace unless brain[gitlabUrl]['repository'][hook.project_id]['namespace']
    brain[gitlabUrl]['repository'][hook.project_id]['url'] = hook.repository.homepage unless brain[gitlabUrl]['repository'][hook.project_id]['url']

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
    query     = querystring.parse(url.parse(req.url).query)
    hook      = req.body
    # git_url   = 
    # namespace = ''
    target    = ''

    # URL
    try
      git_url = hook.repository.homepage
    catch
      try
        p_id = hook.object_attributes.target_project_id
        git_url = brain[gitlabUrl]['repository'][p_id]['url']
        # console.log "R: " + req.headers.referer
        # url -> http://GITLAB/なので、無理
      catch
        console.log "#{prefix}: Unknown git repository."

    try
      target = conf[git_url]['target']
    catch
      try
        target = conf['DEFAULT']['target']
      catch
        console.log "#{prefix}: Please set DEFAULT value."
        return

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
            message.push("#{hook.repository.homepage + '/commit/' + hook.after}")
          else
            if /^0+$/.test(hook.after)
              # branch or tag is deleted.
              message.push("#{@sm.bold(hook.user_name)} deleted #{label} (#{@sm.bold(value)}) to #{@sm.bold(hook.repository.name)}")
              message.push("#{hook.repository.homepage + '/commit/' + hook.before}")
            else
              # normal push event.
              branch     = hook.ref.split("/")[2..].join("/")
              indent     = "    "
              compareUrl = "#{hook.repository.homepage}/compare/#{hook.before.substr(0,9)}...#{hook.after.substr(0,9)}"

              message.push("#{@sm.bold(hook.user_name)} pushed #{@sm.bold(hook.total_commits_count)} commits to #{@sm.bold(branch)} in #{@sm.bold(hook.repository.name)}")
              message.push("#{@sm.url('compare', compareUrl)}")

              if ircType == "slack"
                attachments = []
                attachments.push(@sm.slackCommitMessage(hook.commits))
              else
                for li in @sm.list(hook.commits)
                  message.push(li)

              saveInfo hook, git_url
        else
          if hook.object_kind
            message = makeObjectKindMessage(hook, git_url)
          else
            if hook.event_name
              switch hook.event_name
                when "user_add_to_team"
                  message.push("#{hook.user_name}(#{hook.user_email}) has added to #{hook.project_name} as #{hook.project_access}")
                when "user_create"
                  message.push("User: #{hook.name}(#{hook.email}) has created.")
                else
                  console.log "Unknown message type."
                  console.log "hook: %j", hook
                  console.log "git_url: #{git_url}"
            else
              console.log "Unknown message type."
              console.log "hook: %j", hook
              console.log "git_url: #{git_url}"

        if attachments != false
          @sm.send target, message, attachments
        else
          @sm.send target, message

  robot.router.post "/gitlab/system", (req, res) ->
    handler "system", req, res
    res.end ""

  robot.router.post "/gitlab/web", (req, res) ->
    handler "web", req, res
    res.end ""

