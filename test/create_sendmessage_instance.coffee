class create_sendmessage_instance

  constructor: (robot, type) ->

    @SendMessage = require '../send_message'

    switch type
      when 'irc'
        return this.irc_bot(robot)
      when 'http_post'
        return this.http_post_bot(robot)
      when 'slack'
        return this.slack_bot(robot)
      when 'idobata'
        return this.idobata_bot(robot)
      when 'hipchat'
        return this.hipchat_bot(robot)
      when 'chatwork'
        return this.chatwork_bot(robot)
      else
        console.log "Unknown type: #{type}"
        return

  irc_bot: (robot) ->
    process.env.HUBOT_IRC_TYPE  = 'irc'
    process.env.HUBOT_IRC_LABEL = 'message'
    process.env.HUBOT_IRC_INFO  = './irc_info.json'
    new @SendMessage robot

  http_post_bot: (robot) ->
    process.env.HUBOT_IRC_TYPE      = 'http_post'
    process.env.HUBOT_IRC_MSG_TYPE  = 'html'
    process.env.HUBOT_IRC_MSG_LABEL = 'message'
    new @SendMessage robot

  slack_bot: (robot) ->
    process.env.HUBOT_IRC_TYPE  = 'slack'
    process.env.HUBOT_IRC_INFO  = './irc_info.json'
    new @SendMessage robot

  idobata_bot: (robot) ->
    process.env.HUBOT_IRC_TYPE  = 'idobata'
    process.env.HUBOT_IRC_INFO  = './irc_info.json'
    new @SendMessage robot

  hipchat_bot: (robot) ->
    process.env.HUBOT_IRC_TYPE  = 'hipchat'
    process.env.HUBOT_IRC_INFO  = './hipchat_info.json'
    new @SendMessage robot

  chatwork_bot: (robot) ->
    process.env.HUBOT_IRC_TYPE  = 'chatwork'
    process.env.HUBOT_IRC_INFO  = './irc_info.json'
    new @SendMessage robot

module.exports = create_sendmessage_instance
