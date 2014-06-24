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

url         = require 'url'
querystring = require 'querystring'
request     = require 'request'
SendMessage = require './send_message'

configFile  = process.env.GITLAB_CONFIG_FILE
debug       = process.env.GITLAB_DEBUG?
prefix      = '[gitlab]'

module.exports = (robot) ->

  @sm  = new SendMessage(robot)
  conf = @sm.readJson configFile, prefix
  return unless conf

  target  = conf['target']

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
        # if the ref before the commit is 00000, this is a new branch
        if /^0+$/.test(hook.before)
          branch = hook.ref.split("/")[2..].join("/")
          message.push("#{@sm.bold(hook.user_name)} pushed a new branch (#{@sm.bold(branch)}) to #{@sm.bold(hook.repository.name)} (#{@sm.underline(hook.repository.homepage)})")
        else
          if hook.ref
            # push event
            branch = hook.ref.split("/")[2..].join("/")
            indent = "    "
            compareUrl = "#{hook.repository.homepage + '/compare/' + hook.before.substr(0,9) + '...' + hook.after.substr(0,9)}"
            message.push("#{@sm.bold(hook.user_name)} pushed #{@sm.bold(hook.total_commits_count)} commits to #{@sm.bold(branch)} in #{@sm.bold(hook.repository.name)}")
            message.push("#{@sm.url('compare', compareUrl)}")
            # for c in hook.commits
            #   str = c.message.replace /\n/g, "\n#{indent}"
            #   message.push("  - #{c.id}")
            #   message.push("    #{str}")
            #   # message.push("    #{c.message}")
            #   message.push("    #{c.url}")
            for li in @sm.list(hook.commits)
              message.push(li)
            # message.push(@sm.list(hook.commits))
          # else
          #   if hook.action
          #     switch hook.action
          #       when "opened"
          #       # pull request
          #         message.push("#{@sm.bold(hook.user_name)} pushed a new branch (#{@sm.bold(branch)}) to #{@sm.bold(hook.repository.name)} (#{@sm.underline(hook.repository.homepage)})")

        @sm.send target, message

  robot.router.post "/gitlab/system", (req, res) ->
    handler "system", req, res
    res.end ""

  robot.router.post "/gitlab/web", (req, res) ->
    handler "web", req, res
    res.end ""

