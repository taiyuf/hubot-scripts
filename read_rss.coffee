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
# #   if "RSS_TARGET_TYPE" is http_post, like this,
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
# #   if "type" is irc, like this,
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

prefix     = '[read_rss]:'
timezone   = "Asia/Tokyo"
schedule   = '0 */5 * * * *' # *(sec) *(min) *(hour) *(day) *(month) *(day of the week)
# schedule   = '0 * * * * *' # *(sec) *(min) *(hour) *(day) *(month) *(day of the week)
configFile = process.env.RSS_CONFIG_FILE or '../rss_list.json'
label      = process.env.RSS_LABEL       or 'read_rss'
type       = process.env.RSS_TARGET_TYPE

try
  data = fs.readFileSync configFile, 'utf-8'
  try
    rss = JSON.parse(data)
    console.log "#{prefix} success to load file: #{configFile}."
  catch
    console.log "#{prefix} Error on parsing the json file: #{configFile}"
    return
catch
  console.log "#{prefix} Error on reading the json file: #{configFile}"
  return

unless type == "irc" or type == "http_post"
  console.log "Please set the value of RSS_TARGET_TYPE."
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
          request.post
            url: t
            form: {"source": msg}
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
