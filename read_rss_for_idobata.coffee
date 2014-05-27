# Description
# #   "Simple RSS Reader for idobata."
# #
# # Dependencies:
# #   "request":    "2.34.0"
# #   "feedparser": "0.16.6"
# #
# # Configuration:
# #   RSS_CONFIG_FILE: path to configuration file
# #   RSS_KEYWORD:     if you create many bots, you define a unique keyword.
# #
# #   you need to write configuration file as json format.
# #
# #   like this,
# #
# #   {
# #     "rss feed1": {"url": "http://....",
# #                   "room": ["URL", "URL"]},
# #     "rss feed2": {"url": "http://...",
# #                   "id": "user",
# #                   "password": "password",
# #                   "room": ["URL", "URL"]}
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
label      = process.env.RSS_KEYWORD or 'idobata'
prefix     = '[read_rss]:'
timezone   = "Asia/Tokyo"
schedule   = '0 */5 * * * *' # *(sec) *(min) *(hour) *(day) *(month) *(day of the week)
# schedule   = '0 * * * * *' # *(sec) *(min) *(hour) *(day) *(month) *(day of the week)
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

  request_url = (url, id, password) ->
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

  parse_feed = (req, keyword, room) ->
    fp = new feedparser
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
          console.log "title: #{item.title}"
          if not robot.brain.data[label][item.link]?
            robot.brain.data[label][item.link] = { "keyword": keyword, "room": room }
            console.log "item: #{item}"
            item
        robot.brain.save
      catch error
        console.log "#{prefix} error on reading: #{error}"
        return)


  read_rss = (url, id, password, keyword, room, callback) ->

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
            robot.brain.data[label][item.link] = { "keyword": keyword, "room": room }
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
        read_rss rss[key]['url'], rss[key]['id'], rss[key]['password'], key, rss[key]['room'], (item) ->
          msg = "[#{robot.brain.data[label][item.link]['keyword']}] #{item.title}: #{item.link}"
          urls = robot.brain.data[label][item.link]['room']
          for u in urls
            request.post
              url: u
              form: {"source": msg}
            , (err, response, body) ->
              console.log "err: #{err}" if err?
