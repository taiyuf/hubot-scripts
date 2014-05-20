# Description
# #   "Simple RSS Reader for a given room."
# #
# # Dependencies:
# #   "request": "2.34.0"
# #   "feedparser": "0.16.6"
# #
# # Configuration:
# #   None
# #
# # Commands:
# #   None
# #
# # Author:
# #   Taiyu Fujii

fs         = require 'fs'
path       = require 'path'
cron       = require('cron').CronJob
# feed_url   = "http://redmine.on-net.jp/projects/jsdf/activity.atom?key=7f44b6ed31fe0f04a003a02422351f9afe6d8e93"
feed_url   = "http://news.livedoor.com/topics/rss/top.xml"
feedparser = require 'feedparser'
request    = require 'request'
room       = '#start'
schedule   = '0 * * * * *'
# *(sec) *(min) *(hour) *(day) *(month) *(day of the week)

module.exports = (robot) ->
  send_to_irc = (cronTime, room, url, callback)->

    rssPath = process.env.RSS_FILE_PATH or '../rss_list.json'

    try
      data = fs.readFileSync rssPath, 'utf-8'
      console.log data
      try
        rss = JSON.parse(data)
        console.log "success to load file: #{rssPath}."
      catch
        console.log "Error on parsing the json file: #{rssPath}"
        return
    catch
      console.log "Error on reading the json file: #{rssPath}"
      return

    new cron
      cronTime: cronTime
      start: true
      timeZone: "Asia/Tokyo"
      onTick: ->
        for key of rss
          date    = new Date
          entries = []
          fp      = new feedparser

          console.log "job of #{key}"
          if rss[key]["id"] and rss[key]["password"]
            request(rss[key]["url"])
          else
            request(rss[key]["url"]).auth("{ #{rss[key]["id"]}: #{rss[key]["password"]} }")

          try
            req.pipe(fp)
          catch error
            console.log "Error on reqest: #{error}"

          fp.on('error', (error) ->
            console.log "Error on feedparser: #{error}")

          fp.on('readable', () ->
            try
              while item = @read()
                if not robot.brain.data[url]?[item.link]?
                  callback item
                  robot.brain.data[url][item.link] = true
              robot.brain.save
            catch error
              console.log "error on reading: #{error}"
              return)

  robot.enter ->
    send_to_irc schedule, room, feed_url, (item) ->
      robot.send { room: room }, "#{item.title}: #{item.link}"
