# Description
# #   "Simple RSS Reader."
# #
# # Dependencies:
# #   "request":    "2.34.0"
# #   "feedparser": "0.16.6"
# #
# # Configuration:
# #   RSS_CONFIG_FILE: path to configuration file
# #   RSS_LABEL:       if you create many bots, you define a unique keyword.
# #   RSS_TARGET_TYPE: "http_post" or "irc"
# #
# #   you need to write configuration file as json format.
# #
# #   If you use the group chat system and post message by HTTP POST, you set "RSS_TARGET_TYPE" to "http_post", and configuration file like this,
# #
# #   {
# #     "keyword1": {"feed": {"url": "http://...."},
# #                  "target": ["URL1"]},
# #     "keyword2": {"feed": {"url": "http://...",
# #                           "id": "user",
# #                           "password": "password"},
# #                  "target": ["URL1", "URL2"]}
# #   }
# #
# #   If you use the irc adapter of hubot, you set "type" is irc, and configuratio file like this,
# #
# #   {
# #     "keyword1": {"feed": {"url": "http://...."},
# #                  "target": ["#hoge", "#fuga"]},
# #     "keyword2": {"feed": {"url": "http://...",
# #                           "id": "user",
# #                           "password": "password"},
# #                  "target": ["#hoge", "#foo"]}
# #   }
# #
# #   url, room(idobata channel's url) fields are required. if the site require the basic
# #   authentication, you need to set id, password fields.
# #
# # Commands:
# #   None
# #
# # Author:
# #   Taiyu Fujii

fs         = require 'fs'
path       = require 'path'
cron       = require('cron').CronJob
feedparser = require 'feedparser'
request    = require 'request'

prefix     = '[read_rss]'
timezone   = "Asia/Tokyo"
schedule   = '0 */5 * * * *' # *(sec) *(min) *(hour) *(day) *(month) *(day of the week)
# schedule   = '0 * * * * *' # *(sec) *(min) *(hour) *(day) *(month) *(day of the week)
configFile = process.env.RSS_CONFIG_FILE or '../rss_list.json'
label      = process.env.RSS_LABEL       or 'read_rss'
type       = process.env.RSS_TARGET_TYPE
headerFile = process.env.RSS_CUSTOM_HEADERS

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

rss     = read_json configFile
headers = read_json headerFile if headerFile

unless type == "irc" or type == "http_post" or type == "chatwork"
  console.log "Please set the value of RSS_TARGET_TYPE."
  return

if type == "chatwork"
  unless headers
    console.log "Please set the value of RSS_CUSTOM_HEADERS."
    return

module.exports = (robot) ->

  read_rss = (url, id, password, keyword, target, callback) ->

    fp = new feedparser

    unless id? and password?
      try
        req = request(url)
      catch
        console.log "#{prefix} Error on fetch the url: #{url}"
        return

    else
      try
        auth = new Buffer("#{id}:#{password}").toString('base64')
        req = request({"url": url, "headers": {"Authorization": "Basic #{auth}"}})
      catch
        console.log "#{prefix} Error on fetch the url: #{url}"
        return

    try
      req.pipe(fp)
    catch error
      console.log "#{prefix} Error on reqest: #{error}"

    fp.on('error', (error) ->

      console.log "#{prefix} job of #{url}"
      console.log "#{prefix} Error on feedparser: #{error}")

    fp.on('readable', () ->

      robot.brain.data[label] = {} unless robot.brain.data[label]?

      try
        while item = @read()
          unless robot.brain.data[label][item.link]?
            robot.brain.data[label][item.link] = { "keyword": keyword, "target": target }
            callback item
        robot.brain.save
      catch error
        console.log "#{prefix} error on reading: #{error}"
        return)

  send_msg = (type, target, msg) ->
    for t in target
      switch type
        when "irc"
          robot.send { "room": t }, msg
        when "http_post"
          if headers
            request.post
              url: t
              headers: headers
              form: {"source": msg}
            , (err, response, body) ->
              console.log "err: #{err}" if err?
          else
            request.post
              url: t
              form: {"source": msg}
            , (err, response, body) ->
              console.log "err: #{err}" if err?
        when "chatwork"
          msg = encodeURIComponent "[info]#{msg}[/info]"
          url = "#{t}?body=#{msg}"
          request.post
            url: url
            headers: headers
          , (err, response, body) ->
            console.log "err: #{err}" if err?

  new cron
    cronTime: schedule
    start:    true
    timeZone: timezone
    onTick: ->
      for key of rss
        read_rss rss[key]['feed']['url'], rss[key]['feed']['id'], rss[key]['feed']['password'], key, rss[key]['target'], (item) ->

          msg    = "[#{robot.brain.data[label][item.link]['keyword']}] #{item.title}: #{item.link}"
          target = robot.brain.data[label][item.link]['target']
          send_msg type, target, msg
