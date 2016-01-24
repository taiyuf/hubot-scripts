IrcMessage = require './irc'

class SlackMessage extends IrcMessage

  constructor: (robot) ->

    super(robot)

    @fmtLabel = 'payload'
    @color    = '#aaaaaa'
    @info     = @config.get process.env.HUBOT_IRC_INFO

  bold: (str) ->
    " *#{str}* "

  url: (title, url) ->
    "<#{url}|#{title}>"

  underline: (str) ->
    " *#{str}* "

  build_attachments: (msg, query) ->

    fallback = []
    at       = {}
    messages = @msg_filter msg

    if query.color
      at.color = query.color
    else
      at.color = @color

    at.text  = messages

    fallbacks = [
      'pretext'
      'title'
      'title_link'
    ]

    for f in fallbacks
      fallback.push f if query[f]

    fallback.push(messages)
    at.fallback = fallback.join(' - ')

    at.mrkdwn_in = ['text', 'pretext']

    querys = [
      'pretext'
      'title'
      'title_link'
      'author_name'
      'author_link'
      'author_icon'
      'image_url'
      'thumb_url'
      'fields'
      'color'
    ]
    for q in querys
      at[q] = query[q]

    if query.mrkdwn
      at.mrkdwn = query.mrkdwn
    else
      at.mrkdwn = true

    if @debug
      @log.debug at, "attachment: "

    [at]

  send: (target, msg, query) ->

    q = {}

    # required
    q.channel     = target
    # q.text        = query.message

    # option
    q.attachments = @build_attachments msg, query

    params = [
      'color'
      'username'
      'as_user'
      'parse'
      'link_name'
      'unfurl_links'
      'unfurl_media'
      'icon_url'
      'icon_emoji'
    ]

    for p in params
      q[p] = query[p] if query[p]

    @log.debug JSON.stringify q, 'json: '

    @request
      url: @info.webhook_url
      method: "POST"
      json: q
    , (err, res, body) =>
      if err
        @log.warn err, 'err: '
        return

      @log.debug body, 'body from slack: '
      return body

module.exports = SlackMessage
