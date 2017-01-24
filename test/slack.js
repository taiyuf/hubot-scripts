import assert from 'power-assert';
import nock from 'nock';
import path from 'path';
import Slack from '../src/Slack';
let slack;

describe('Slack', () => {
  before((done) => {
    process.env.HUBOT_IRC_INFO = path.resolve(__dirname, './test_slack.yml');
    slack = new Slack({});
    done();
  });

  describe('bold', () => {
    it('should print bold text.', () => {
      const text = 'foo';
      const expected = ` *${text}* `;

      assert(slack.bold(text) == expected);
    });
  });

  describe('url', () => {
    it('should print url text.', () => {
      const url   = 'http://localhost/foo';
      const title = 'bar';
      const expected = `<${url}|${title}>`;

      assert(slack.url(title, url) == expected);
    });
  });

  describe('underline', () => {
    it('should print underline text.', () => {
      const text     = 'foo';
      const expected = ` *${text}* `;

      assert(slack.underline(text) == expected);
    });
  });

  describe('buildAttatchment', () => {
    it('should make valid hash.', () => {
      const title = 'foo';
      const msg   = 'bar';
      const color = 'baz';
      const link  = 'http://localhost/foo';
      const expected = [
        {
          color: '#aaaaaa',
          text: 'bar',
          pretext: 'bar',
          fallback: 'bar',
          mrkdwn_in: [ 'text', 'pretext' ]
        }
      ];
      assert.deepEqual(slack.buildAttatchment(msg), expected);
    });

    it('should make valid hash.', () => {
      const title = 'foo';
      const msg   = 'bar';
      const color = 'baz';
      const link  = 'http://localhost/foo';
      const expected = [
        {
          color: color,
          text: 'bar',
          pretext: 'bar',
          fallback: 'bar',
          mrkdwn_in: [ 'text', 'pretext' ]
        }
      ];
      assert.deepEqual(slack.buildAttatchment(msg, { color: color }), expected);
    });
  });

  describe('send', () => {
    it('should valid request.', (done) => {
      const msg    = 'foo';
      const target = 'bar';
      const hash   = {"channel":"bar","attachments":[{"color":"#aaaaaa","text":"foo","pretext":"foo","fallback":"foo","mrkdwn_in":["text","pretext"]}]};

      nock(`http://localhost`)
        .post(`/foo/bar`, JSON.stringify(hash))
        .reply(200, 'OK');

      slack.send(target, msg, {}, (err, res) => {
        if (err) {
          console.log(err);
          done();
        } else {
          assert(res == 'OK');
          done();
        }
      });
    });
  });


});
