# Description
# #   "Simple RSS Reader for irc."
# #
# # Dependencies:
# #   "request":    "2.34.0"
# #   "feedparser": "0.16.6"
# #
# # Configuration:
# #   RSS_CONFIG_FILE: path to configuration file
# #
# #   you need to write configuration file as json format.
# #
# #   like this,
# #
# #   {
# #     "rss feed1": {"url": "http://....",
# #                   "room": ["#hoge", "#fuga"]},
# #     "rss feed2": {"url": "http://...",
# #                   "id": "user",
# #                   "password": "password",
# #                   "room": ["#hoge", "#fuga"]}
# #   }
# #
# #   url, room(irc channel) fields are required. if the site require the basic
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
configFile = process.env.RSS_CONFIG_FILE or '../rss_list.json'

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

module.exports = (robot) ->
  send_to_irc = (url, id, password, label, room, callback)->

    new cron
      cronTime: schedule
      start:    true
      timeZone: timezone
      onTick: ->

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
          try
            while item = @read()
              if not robot.brain.data[item.link]?
                robot.brain.data[item.link] = { "label": label, "room": room }
                callback item
            robot.brain.save
          catch error
            console.log "#{prefix} error on reading: #{error}"
            return)

  robot.enter ->
    for key of rss
      send_to_irc rss[key]['url'], rss[key]['id'], rss[key]['password'], key, rss[key]['room'], (item) ->
        for r in robot.brain.data[item.link]['room']
          robot.send { "room": r }, "[#{robot.brain.data[item.link]['label']}] #{item.title}: #{item.link}"
