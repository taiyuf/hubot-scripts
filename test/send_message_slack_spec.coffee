require './helper'

src   = process.env.HOME + "/node_modules/hubot/src"
Robot = require(src + "/robot")
Slack = require '../send_message/slack'
slack = new Slack
fs    = require 'fs'

describe 'text decoration', ->

  it '.bold', ->
    expect(slack.bold('foo')).to.equal ' *foo* '

  it '.url', ->
    expect(slack.url('foo', 'http://bar')).to.equal '<http://bar|foo>'

  it '.underline', ->
    expect(slack.underline('foo')).to.equal ' *foo* '

describe 'handling', ->

  describe '.build_attachments', ->
    it 'should have no options.', ->
      at     = slack.build_attachments 'foo', {}
      result = [
        {
          color:    "#aaaaaa"
          text:     "foo"
          fallback: "foo"
          mrkdwn_in: [
            "text"
            "pretext"
            ]
          mrkdwn:   true
        }
      ]

      expect(at).to.equal JSON.stringify(result)

    it 'should have full options.', ->
      options = {
        fallback: 'a'
        color: 'b'
        pretext: 'c'
        author_name: 'd'
        author_link: 'e'
        author_icon: 'f'
        title: 'g'
        title_link: 'h'
        fields: 'i'
        image_url: 'j'
        thumb_url: 'k'
      }
      at     = slack.build_attachments 'foo', options
      result = [
        {
          color: "b"
          text: "foo"
          fallback: "c - g - h - foo"
          mrkdwn_in: ["text","pretext"]
          pretext: "c"
          title: "g"
          title_link: "h"
          author_name: "d"
          author_link: "e"
          author_icon: "f"
          image_url: "j"
          thumb_url: "k"
          fields: "i"
          mrkdwn: true
        }
      ]

      expect(at).to.equal JSON.stringify(result)

  # it '.commitMessage', ->
  #   event    = JSON.parse(fs.readFileSync './test/sample/gitlab_push_events.json', 'utf-8')
  #   # console.log "cs: %j", event['commits']
  #   fallback0 = 'b6568db1: Update Catalan translation to e38cb41.\n- Jordi Mallach'
  #   text0     = '<http://example.com/mike/diaspora/commit/b6568db1bc1dcd7f8b4d5a946b0b91f9dacd7327|b6568db1>: Update Catalan translation to e38cb41.\n- Jordi Mallach'
  #   color     = '#123456'
  #   fallback1 = 'da156088: fixed readme\n- GitLab dev user'
  #   text1     = '<http://example.com/mike/diaspora/commit/da1560886d4f094c3e6c9ef40349f7d38b5d27d7|da156088>: fixed readme\n- GitLab dev user'
  #   result    = slack.commitMessage(event['commits'], '#123456')
  #   # console.log "ev: %j", expect
  #   expect(result[0]['fallback']).to.equal fallback0
  #   expect(result[0]['text']).to.equal     text0
  #   expect(result[0]['color']).to.equal    color
  #   expect(result[1]['fallback']).to.equal fallback1
  #   expect(result[1]['text']).to.equal     text1
  #   expect(result[1]['color']).to.equal    color

