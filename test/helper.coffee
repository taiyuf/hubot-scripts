global.expect = require('chai').expect
global.chai   = require 'chai'
global.nock   = require 'nock'

global.shared_context = {}
global.shared_context.robot_is_running = (callback) ->
  robot   = null
  adapter = null
  user    = null

  beforeEach (done) ->
    setupRobot (ret) ->
      robot = ret.robot
      callback ret
      done()

  afterEach ->
    robot.shutdown()

src   = process.env.HOME + "/hubot/node_modules/hubot/src"
Robot = require(src + "/robot")

setupRobot = (callback) ->
  robot   = null
  adapter = null
  user    = null
  robot   = new Robot null, 'mock-adapter', false, 'hubot'

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

# global.sleep = (ms) ->
#   start = new Date().getTime()
#   continue while new Date().getTime() - start < ms
# module.exports = setupRobot

