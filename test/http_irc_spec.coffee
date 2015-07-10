require './helper'

process.env.HUBOT_IRC_ROOMS  = "#dummy"
process.env.HUBOT_IRC_SERVER = "hoge"
process.env.CMD_CONFIG       = "./test/cmd_config.json"

src         = process.env.HOME + "/node_modules/hubot/src"
Robot       = require(src + "/robot")
TextMessage = require(src + "/message").TextMessage
request     = require 'request'

describe 'IRC', ->

  process.env.HUBOT_IRC_TYPE   = 'irc'

  {robot, user, adapter} = {}

  shared_context.robot_is_running (ret) ->
    {robot, user, adapter} = ret

  beforeEach (done) ->
    require('../cmd.coffee')(robot)
    done()

  # it 'get method', (done) ->
  #   adapter.on 'send', (envelope, strings) ->
  #     expect(strings[0]).to.equal('test message')
  #     done()

  #   adapter.receive new TextMessage user, 'test message.'
