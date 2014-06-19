# Description:
#   Post gitlab related events using gitlab hooks
#
# Dependencies:
#   "request":     "2.34.0"
#   "url" :        ""
#   "querystring": ""
#
# Configuration:
#   GITLAB_CONFIG_FILE: the path to configuration file.
#
#   configuration file like below,
#
#   {
#        "type": "irc",
#        "target": ["#hoge"],
#        "headers": {"hoge": "fuga", ... } # optional
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
# Author:
#   Taiyu Fujii

fs          = require 'fs'
path        = require 'path'
url         = require 'url'
querystring = require 'querystring'
request     = require 'request'

configFile = process.env.GITLAB_CONFIG_FILE
debug      = process.env.GITLAB_DEBUG?
headerFile = process.env.GITLAB_CUSTOM_HEADERS
prefix     = '[gitlab]'

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
# headers = read_json headerFile if headerFile
headers = dst['headers']
type    = dst['type']

unless type == "irc" or type == "http_post" or type == "chatwork"
  console.log "Please set the value of 'type' in GITLAB_CONFIG_FILE."
  return

if type == "chatwork"
  unless headers
    console.log "Please set the value of 'headers' in GITLAB_CONFIG_FILE."
    return


module.exports = (robot) ->

  if robot.adapter.constructor.name is 'IrcBot'
    bold = (text) ->
      "\x02" + text + "\x02"
    underline = (text) ->
      "\x1f" + text + "\x1f"
  else
    bold = (text) ->
      text
    underline = (text) ->
      text

  trim_commit_url = (u) ->
    u.replace(/(\/[0-9a-f]{9})[0-9a-f]+$/, '$1')

  send_msg = (type, target, msg) ->
    for t in target
      switch type
        when "irc"
          robot.send { "room": t }, msg
        when "http_post"
          unless headers
            request.post
              url: t
              form: {"source": msg}
            , (err, response, body) ->
              console.log "err: #{err}" if err?
          else
            request.post
              url: t
              headers: headers
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

  handler = (mode, req, res) ->

    console.log("hook: %j", req.body) if debug
    query = querystring.parse(url.parse(req.url).query)
    hook  = req.body

    switch mode
      when "system"
        switch hook.event_name
          when "project_create"
            send_msg type, dst['target'], "Yay! New gitlab project #{bold(hook.name)} created by #{bold(hook.owner_name)} (#{bold(hook.owner_email)})"
          when "project_destroy"
            send_msg type, dst['target'], "Oh no! #{bold(hook.owner_name)} (#{bold(hook.owner_email)}) deleted the #{bold(hook.name)} project"
          when "user_add_to_team"
            send_msg type, dst['target'], "#{bold(hook.project_access)} access granted to #{bold(hook.user_name)} (#{bold(hook.user_email)}) on #{bold(hook.project_name)} project"
          when "user_remove_from_team"
            send_msg type, dst['target'], "#{bold(hook.project_access)} access revoked from #{bold(hook.user_name)} (#{bold(hook.user_email)}) on #{bold(hook.project_name)} project"
          when "user_create"
            send_msg type, dst['target'], "Please welcome #{bold(hook.name)} (#{bold(hook.email)}) to Gitlab!"
          when "user_destroy"
            send_msg type, dst['target'], "We will be missing #{bold(hook.name)} (#{bold(hook.email)}) on Gitlab"

      when "web"
        message = []
        branch = hook.ref.split("/")[2..].join("/")
        # if the ref before the commit is 00000, this is a new branch
        if /^0+$/.test(hook.before)
          message.push("#{bold(hook.user_name)} pushed a new branch (#{bold(branch)}) to #{bold(hook.repository.name)} (#{underline(hook.repository.homepage)})")
        else
          message.push("#{bold(hook.user_name)} pushed #{bold(hook.total_commits_count)} commits to #{bold(branch)} in #{bold(hook.repository.name)} (#{underline(hook.repository.homepage + '/compare/' + hook.before.substr(0,9) + '...' + hook.after.substr(0,9))})")
          indent = "    "
          for c in hook.commits
            str = c.message.replace /\n/g, "\n#{indent}"
            message.push("  - #{c.id}")
            message.push("    #{str}")
            # message.push("    #{c.message}")
            message.push("    #{c.url}")

        send_msg type, dst['target'], message.join("\n")

  robot.router.post "/gitlab/system", (req, res) ->
    handler "system", req, res
    res.end ""

  robot.router.post "/gitlab/web", (req, res) ->
    handler "web", req, res
    res.end ""

