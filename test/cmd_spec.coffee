require './helper'

process.env.HUBOT_IRC_ROOMS  = "#dummy"
process.env.HUBOT_IRC_SERVER = "hoge"
process.env.CMD_CONFIG       = "./test/cmd_config.json"

src         = process.env.HOME + "/node_modules/hubot/src"
Robot       = require(src + "/robot")
TextMessage = require(src + "/message").TextMessage

describe 'IRC', ->

  process.env.HUBOT_IRC_TYPE   = 'irc'

  {robot, user, adapter} = {}

  shared_context.robot_is_running (ret) ->
    {robot, user, adapter} = ret

  beforeEach (done) ->
    require('../cmd.coffee')(robot)
    done()

  it 'regular -> pending'
  # it 'regular', (done) ->
  #   adapter.on 'send', (envelope, strings) ->
  #     console.log "string: %j", strings
  #     expect(strings[0]).to.equal("[cmd] test echo\n\ntest command")
  #     done()

  #   adapter.on 'send', (envelope, strings) ->
  #     console.log "string: %j", strings
  #     expect(strings[0]).to.equal("[Result]\n\ntest\n")
  #     done()

  #   adapter.receive new TextMessage user, 'hubot cmd test echo'

  it 'Not valid user', (done) ->
    adapter.on 'send', (envelope, strings) ->
      expect(strings[0]).to.equal("Permission error!\n\nSorry, You are not allowed to let me order: undefined.")
      done()

    adapter.receive new TextMessage 'foo', 'hubot cmd test echo'

  it 'Not valid target', (done) ->
    adapter.on 'send', (envelope, strings) ->
      expect(strings[0]).to.equal("Target not found\n\ntarget not found: hoge.\n\nSee HUBOT_NAME cmd help.")
      done()

    adapter.receive new TextMessage user, 'hubot cmd hoge echo'

  it 'Not valid action', (done) ->
    adapter.on 'send', (envelope, strings) ->
      expect(strings[0]).to.equal("Action not found\n\naction not found: hoge.\n\nSee HUBOT_NAME cmd help.")
      done()

    adapter.receive new TextMessage user, 'hubot cmd test hoge'

  it '.help', (done) ->
    adapter.on 'send', (envelope, strings) ->
      expect(strings[0]).to.equal('Usage: cmd TARGET ACTION.\n\nYour order is not match my task list. Please check again.\n\n- test echo: `echo test`\ntest command.\n  by mocha')
      done()

    adapter.receive new TextMessage user, 'hubot cmd help'

  # it '.other', (done) ->
  #   adapter.on 'send', (envelope, strings) ->
  #     expect(strings[0]).to.equal('Usage: cmd TARGET ACTION.\n\nYour order is not match my task list. Please check again.')
  #     done()

  #   adapter.receive new TextMessage user, 'hubot cmd hoge'
