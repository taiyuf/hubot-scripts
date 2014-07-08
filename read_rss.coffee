# Description
#   Simple RSS Reader.
#
# Dependencies:
#   "request":    "2.34.0"
#   "feedparser": "0.16.6"
#
# Configuration:
#   RSS_CONFIG_FILE: path to configuration file
#   RSS_LABEL:       if you create many bots, you define a unique keyword.
#
#   If you use the irc adapter of hubot, you set "type" is irc, and configuratio file like this,
#
#   {
#     "keyword1": {"feed": {"url": "http://...."},
#                  "target": ["#hoge", "#fuga"]},                # IRC
#     "keyword2": {"feed": {"url": "http://...",
#                           "id": "user",
#                           "password": "password"},
#                  "target": ["END_POINT_URL", "END_POINT_URL"]} # Other
#   }
#
#   url, room(idobata channel's url) fields are required. if the site require the basic
#   authentication, you need to set id, password fields.
#
# Commands:
#   None
#
# Author:
#   Taiyu Fujii

cron        = require('cron').CronJob
feedparser  = require 'feedparser'
request     = require 'request'
SendMessage = require './send_message'

prefix     = '[read_rss]'
timezone   = "Asia/Tokyo"
schedule   = '0 */5 * * * *' # *(sec) *(min) *(hour) *(day) *(month) *(day of the week)
# schedule   = '0 * * * * *' # *(sec) *(min) *(hour) *(day) *(month) *(day of the week)
configFile = process.env.RSS_CONFIG_FILE or '../rss_list.json'
label      = process.env.RSS_LABEL       or 'read_rss'

module.exports = (robot) ->

  @sm = new SendMessage(robot)
  rss = @sm.readJson configFile, prefix
  return unless rss

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

  new cron
    cronTime: schedule
    start:    true
    timeZone: timezone
    onTick: ->
      for key of rss
        read_rss rss[key]['feed']['url'], rss[key]['feed']['id'], rss[key]['feed']['password'], key, rss[key]['target'], (item) ->
          msg = []
          console.log "item: %j", item
          msg.push("[#{robot.brain.data[label][item.link]['keyword']}] #{@sm.url(item.title, item.link)}")
          msg.push("author: #{item.author}, date: #{item.date}")
          if item.description
            msg.push('')
            msg.push("#{@sm.htmlFilter(item.description)}") if item.description
          target = robot.brain.data[label][item.link]['target']
          @sm.send target, msg
