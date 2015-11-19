IrcMessage = require './irc'

class SlackMessage extends IrcMessage

  constructor: (robot) ->

    super(robot)

    @fmtLabel = 'payload'
    @color    = '#aaaaaa'
    @token    = process.env.HUBOT_SLACK_TOKEN
    @uri      = 'https://slack.com/api/chat.postMessage'
    @debug    = process.env.HUBOT_SLACK_DEBUG

  bold: (str) ->
    ' *' + str + '* '

  url: (title, url) ->
    '<' + url + '|' + title + '>'

  underline: (str) ->
    ' *' + str + '* '

  commitMessage: (commits, color) ->
    fallback = []
    fields   = []
    result   = []

    unless color
      color = @color

    for cs in commits
      text     = []
      fallback = []
      cstr     = cs.message.replace /\n/g, @lineFeed

      # fallback
      fallback.push("#{cs.id[0..7]}: #{cstr}")
      fallback.push("- #{cs.author.name}")

      # fields
      c_title = @url("#{cs.id[0..7]}", cs.url)
      text.push("#{c_title}: #{cs.message}")
      text.push("- #{cs.author.name}")

      result.push({ fallback: fallback.join(@lineFeed), text: text.join(@lineFeed), color: color })
    return result

  build_default_attachments: (msg, query) ->

    fallback = []
    at       = {}
    at.text  = msg

    if query.color
      color = query.color
    else
      color = @color

    at.color = color

    if query.pretext
      fallback.push(query.pretext)

    if query.title
      fallback.push(query.title)

    if query.title_link
      fallback.push(query.title_link)

    fallback.push(msg)
    at.fallback = fallback.join(' - ')

    at.mrkdwn_in = ['text', 'pretext']

    if query.pretext
      at.pretext = query.pretext

    if query['title']
      at.title = query.title

    if query.title_link
      at.title_link = query.title_link

    if query.author_name
      at.author_name = query.author_name

    if query.author_link
      at.author_link = query.author_link

    if query.author_icon
      at.author_icon = query.author_icon

    if query.image_url
      at.image_url = query.image_url

    if query.thumb_url
      at.thumb_url = query.thumb_url

    if query.fields
      at.fields = query.fields

    if query.mrkdwn
      at.mrkdwn = query.mrkdwn
    else
      at.mrkdwn = true

    if @debug
      console.log "at: %j", JSON.stringify({ 'attachments': [ at ] })

    at

  default: (target, msg, query) ->

    at = @build_default_attachments msg, query
    @send target, JSON.stringify([ at ]), query

  send: (target, attachments, query) ->

    q = {}

    # required
    q.token       = @token
    q.channel     = target
    # q.text        = query.message

    # option
    q.attachments = attachments

    if query.username
      q.username = query.username

    if query.as_user
      q.as_user = query.as_user

    if query.parse
      q.parse = query.parse

    if query.link_names
      q.link_names = query.link_names

    if query.unfurl_links
      q.unfurl_links = query.unfurl_links

    if query.unfurl_media
      q.unfurl_media = query.unfurl_media

    if query.icon_url
      q.icon_url = query.icon_url

    if query.icon_emoji
      q.icon_emoji = query.icon_emoji

    url = "#{@uri}?#{@querystring.stringify(q)}"

    if @debug
      console.log "query: %j", query
      console.log "url: #{url}"

    @request.get url, (err, response, body) ->
      console.log "err: #{err}" if err?

module.exports = SlackMessage
