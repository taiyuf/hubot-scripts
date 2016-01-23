require './helper'

process.env.HUBOT_IRC_ROOMS  = "#dummy"
process.env.HUBOT_IRC_SERVER = "hoge"

src         = process.env.HOME + "/node_modules/hubot/src"
Robot       = require(src + "/robot")
TextMessage = require(src + "/message").TextMessage
request     = require 'request'
port        = 29999

describe 'Robot', ->

  process.env.HUBOT_IRC_TYPE   = 'irc'
  process.env.PORT             = port
  process.env.allow            = ['192.168.11.1', '192.168.11.2']
  process.env.deny             = ['192.168.11.3', '192.168.11.4']
  Http_Irc                     = require('../http_irc.coffee')

  {robot, user, adapter} = {}

  shared_context.robot_is_running (ret) ->
    {robot, user, adapter} = ret

  beforeEach (done) ->
    require('../http_irc.coffee')(robot)
    done()

  # before (done) ->
  #   require('../http_irc.coffee')(robot)
  #   setupRobot (ret) ->
  #     {robot, user, adapter} = ret
  #     done()

  # after ->
  #   robot.shutdown()

  describe 'check_ip', ->

    req = {}
    req.headers = {}
    req.connection = {}
    http_irc = null

    beforeEach (done) ->
      http_irc = new Http_Irc robot
      done()

    # it 'remote ip is denied.', ->

    #   req.connection['remoteAddres'] = '192.168.11.3'

    #   adapter.on 'send', (envelope, strings) ->
    #     expect(strings[0]).to.equal('')
    #     done()


  # it 'get method', (done) ->
  #   adapter.on 'send', (envelope, strings) ->
  #     expect(strings[0]).to.equal('test.')
  #     done()

  #   request.get "http://localhost:#{port}/http_irc?message=test.&room=%23mocha"

  # it 'post method', (done) ->
  #   adapter.on 'send', (envelope, strings) ->
  #     expect(strings[0]).to.equal('test.')
  #     done()

  #   request.post
  #     url: "http://localhost:#{port}/http_irc"
  #     form: {room: '%23mocha', message: 'test.'}


setupRobot = (callback) ->
  robot   = null
  adapter = null
  user    = null
  robot   = new Robot null, 'mock-adapter', true, 'hubot'

  robot.adapter.on 'connected', ->
    user  = robot.brain.userForId '1',
      name: 'mocha'
      room: '#mocha'

    adapter = robot.adapter
    _on = adapter.on

    adapter.on = (event, callback, done) ->
      wrapCallback = (envelope, strings) ->
        try
          callback envelope, strings
          if done
            done()
        catch e
          if done
            done e
          else
            throw e

      _on.apply this, [event, wrapCallback]

    callback robot: robot, user: user, adapter: adapter

  robot.run()
