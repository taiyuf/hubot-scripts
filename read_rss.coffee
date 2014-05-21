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
feedparser = require 'feedparser'
request    = require 'request'
label      = 'read_rss'
schedule   = '0 * * * * *' # *(sec) *(min) *(hour) *(day) *(month) *(day of the week)
rssPath    = process.env.RSS_FILE_PATH or '../rss_list.json'

try
  data = fs.readFileSync rssPath, 'utf-8'
  try
    rss = JSON.parse(data)
    console.log "#{label} success to load file: #{rssPath}."
  catch
    console.log "#{label} Error on parsing the json file: #{rssPath}"
catch
  console.log "#{label} Error on reading the json file: #{rssPath}"

module.exports = (robot) ->
  send_to_irc = (cronTime, callback)->

    new cron
      cronTime: cronTime
      start: true
      timeZone: "Asia/Tokyo"
      onTick: ->
        for key of rss

          fp   = new feedparser
          url  = rss[key]['url']
          room = rss[key]['room']
          date = new Date

          if not rss[key]['room']
            console.log "#{label} not defined 'room'."
            return

          if rss[key]["id"] and rss[key]["password"]
            try
              auth = new Buffer("#{rss[key]['id']}:#{rss[key]['password']}").toString('base64')
              req = request({url: url, headers: {"Authorization": "Basic #{auth}"}})
            catch
              console.log "#{label} Error on fetch the url: #{url}"
              return
          else
            try
              req = request(rss[key]["url"])
            catch
              console.log "#{label} Error on fetch the url: #{url}"
              return

          try
            req.pipe(fp)
          catch error
            console.log "#{label} Error on reqest: #{error}"

          fp.on('error', (error) ->
            console.log "#{label} job of #{url}"
            console.log "#{label} Error on feedparser: #{error}")

          fp.on('readable', () ->
            try
              while item = @read()
                if not robot.brain.data[url]?[item.link]?
                  robot.brain.data[url][item.link] = true
                  callback item, room
              robot.brain.save
            catch error
              console.log "#{label} error on reading: #{error}"
              return)

  robot.enter ->
    send_to_irc schedule, (item, room) ->
      for r in room
        robot.send { room: r }, "#{item.title}: #{item.link}"
