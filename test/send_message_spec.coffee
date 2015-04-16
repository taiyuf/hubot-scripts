require './helper'

process.env.HUBOT_IRC_ROOMS  = "#dummy"
process.env.HUBOT_IRC_SERVER = "hoge"

src         = process.env.HOME + "/hubot/node_modules/hubot/src"
Robot       = require(src + "/robot")
TextMessage = require(src + "/message").TextMessage
SendMessage = require '../send_message'
CS          = require './create_sendmessage_instance'

describe 'test: ', ->

  process.env.HUBOT_IRC_TYPE  = 'irc'
  process.env.HUBOT_IRC_INFO  = './irc_info.json'

  {robot, user, adapter} = {}

  shared_context.robot_is_running (ret) ->
    {robot, user, adapter} = ret

  describe 'basic method', ->

    before (done) ->
      sm = new CS 'irc'
      done()

    it '.readJson nofiles', ->
      try
        expect(sm.readJson 'not_exist.json', 'test').to.equal(null)
      catch e
        expect(e.message).to.equal('expected undefined to equal null')

    it 'not valid json'

    it 'valid json', ->
      json = sm.readJson './test/irc_info.json'
      expect(json['header']['X-API-Token']).to.equal('XXXXXXXXXXXX')


  # describe 'initialize'

  describe 'bold', ->

    it 'irc', ->
      sm = new CS robot, 'irc'
      expect(sm.bold 'hoge').to.equal('\x02hoge\x02')

    it 'http_post', ->
      sm = new CS robot, 'http_post'
      expect(sm.bold 'hoge').to.equal('<strong>hoge</strong>')

    it 'slack', ->
      sm = new CS robot, 'slack'
      expect(sm.bold 'hoge').to.equal(' *hoge* ')

    it 'idobata', ->
      sm = new CS robot, 'idobata'
      expect(sm.bold 'hoge').to.equal('<b>hoge</b>')

    it 'hipchat', ->
      sm = new CS robot, 'hipchat'
      expect(sm.bold 'hoge').to.equal('hoge')

    it 'chatwork', ->
      sm = new CS robot, 'chatwork'
      expect(sm.bold 'hoge').to.equal('hoge')

  describe 'url', ->

    it 'irc', ->
      sm = new CS robot, 'irc'
      expect(sm.url 'hoge', 'url').to.equal('\x1fhoge\x1f: url')

    it 'http_post', ->
      sm = new CS robot, 'http_post'
      expect(sm.url 'hoge', 'url').to.equal('<a href=\'url\' target=\'_blank\'>hoge</a>')

    it 'slack', ->
      sm = new CS robot, 'slack'
      expect(sm.url 'hoge', 'url').to.equal('<url|hoge>')

    it 'idobata', ->
      sm = new CS robot, 'idobata'
      expect(sm.url 'hoge', 'url').to.equal('<a href=\'url\' target=\'_blank\'>hoge</a>')

    it 'hipchat', ->
      sm = new CS robot, 'hipchat'
      expect(sm.url 'hoge', 'url').to.equal('hoge: url')

    it 'chatwork', ->
      sm = new CS robot, 'chatwork'
      expect(sm.url 'hoge', 'url').to.equal('hoge: url')

  describe 'underline', ->

    it 'irc', ->
      sm = new CS robot, 'irc'
      expect(sm.underline 'hoge').to.equal('\x1fhoge\x1f')

    it 'http_post', ->
      sm = new CS robot, 'http_post'
      expect(sm.underline 'hoge').to.equal('<u>hoge</u>')

    it 'slack', ->
      sm = new CS robot, 'slack'
      expect(sm.underline 'hoge').to.equal(' *hoge* ')

    it 'idobata', ->
      sm = new CS robot, 'idobata'
      expect(sm.underline 'hoge').to.equal('<b>hoge</b>')

    it 'hipchat', ->
      sm = new CS robot, 'hipchat'
      expect(sm.underline 'hoge').to.equal('hoge')

    it 'chatwork', ->
      sm = new CS robot, 'chatwork'
      expect(sm.underline 'hoge').to.equal('hoge')

  describe 'makeHtmlList', ->

    before (done) ->
      sm      = new CS robot, 'http_post'
      commits = [{id: '1', url: 'url1', message: 'message 1'},{id: '2', url: 'url2', message: 'message 2'}]
      @array  = sm.makeHtmlList(commits)
      done()

    it 'result', ->

      expect(@array[0]).to.equal('<ul><li><a href=\'url1\' target=\'_blank\'>1</a><br />message 1</li><li><a href=\'url2\' target=\'_blank\'>2</a><br />message 2</li></ul>')

  describe 'slackCommitMessage', ->
    # result = {"fallback":"\u001flink\u001f: url1\nmessage 1\n\n\n\n\n\u001flink\u001f: url2\nmessage 2\n\n\n\n","fields":[{"title":"* 1","value":"\u001flink\u001f: url1\nmessage 1\n\n\n\n"},{"title":"* 2","value":"\u001flink\u001f: url2\nmessage 2\n\n\n\n"}],"color":"#aaaaaa","mrkdwn_in":["fallback","fields"]}

    before (done) ->
      sm      = new CS robot, 'slack'
      commits = [{id: '1', url: 'url1', message: 'message 1'},{id: '2', url: 'url2', message: 'message 2'}]
      @hash    = sm.slackCommitMessage(commits)
      done()

    it 'fallback', ->
      expect(@hash['fallback']).to.equal('<url1|link><br />message 1<br /><br /><br /><br /><br /><url2|link><br />message 2<br /><br /><br /><br />')

    it 'fields', ->
      expect(@hash['fields'][0]['title']).to.equal('* 1')
      expect(@hash['fields'][0]['value']).to.equal('<url1|link><br />message 1<br /><br /><br /><br />')
      expect(@hash['fields'][1]['title']).to.equal('* 2')
      expect(@hash['fields'][1]['value']).to.equal('<url2|link><br />message 2<br /><br /><br /><br />')

  describe 'makeMarkdownList', ->

    before (done) ->
      sm      = new CS robot, 'slack'
      commits = [{id: '1', url: 'url1', message: 'message 1'},{id: '2', url: 'url2', message: 'message 2'}]
      @array  = sm.makeMarkdownList(commits)
      done()

    it 'result', ->
      expect(@array[0]).to.equal('* <url1|1>')
      expect(@array[1]).to.equal('* <url2|2>')

  describe 'makeStrList', ->
    before (done) ->
      sm      = new CS robot, 'irc'
      commits = [{id: '1', url: 'url1', message: 'message 1'},{id: '2', url: 'url2', message: 'message 2'}]
      @array  = sm.makeStrList(commits)
      done()

    it 'result', ->
      expect(@array[0]).to.equal('  - 1')
      expect(@array[1]).to.equal('    message 1')
      expect(@array[2]).to.equal('    url1')
      expect(@array[3]).to.equal('  - 2')
      expect(@array[4]).to.equal('    message 2')
      expect(@array[5]).to.equal('    url2')

  describe 'list', ->

    before ->
      commits = [{id: '1', url: 'url1', message: 'message 1'},{id: '2', url: 'url2', message: 'message 2'}]

      it 'irc', ->
        sm    = new CS robot, 'irc'
        array = sm.list(commits)
        expect(@array[0]).to.equal('  - 1')
        expect(@array[1]).to.equal('    message 1')
        expect(@array[2]).to.equal('    url1')
        expect(@array[3]).to.equal('  - 2')
        expect(@array[4]).to.equal('    message 2')
        expect(@array[5]).to.equal('    url2')
