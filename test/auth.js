import assert from 'power-assert';
import nock from 'nock';
import path from 'path';
import Auth from '../src/Auth';
let auth;
const req = {
  headers: {
    'x-forwarded-for': '127.0.0.1',
    'hubot_http_irc_api_key': 'foo'
  }
};
const writeHead = () => console.log;
const end       = () => console.log;
const res = {
  writeHead: writeHead,
  end: end
}

describe('Auth', () => {
  before((done) => {
    auth = new Auth(req);
    done();
  });

  describe('match', () => {
    describe('ip pattern', () => {
      it('should match in success.', () => {
        const pattern = '127.0.0.1';
        assert(auth.match(pattern) == true);
      });

      it('should match in fail.', () => {
        const pattern = '127.0.0.2';
        assert(auth.match(pattern) == false);
      });
    });

    describe('network pattern', () => {
      it('should match in success.', () => {
        const pattern = '127.0.0.';
        assert(auth.match(pattern) == true);
      });

      it('should match in fail.', () => {
        const pattern = '192.168.';
        assert(auth.match(pattern) == false);
      });
    });
  });

  describe('checkIp', () => {
    it('should deny.', () => {
      auth.deny = ['127.0.0.1'];
      assert(auth.checkIp() == false);
    });

    it('should deny.', () => {
      auth.deny = [''];
      auth.allow = ['127.0.0.1'];
      assert(auth.checkIp() == true);
      auth.allow = [''];
    });
  });

  describe('checkApiKey', () => {
    it('should allow', () => {
      auth.apikey = 'foo';
      assert(auth.checkApiKey() == true);
    });

    it('should deny', () => {
      auth.apikey = 'bar';
      assert(auth.checkApiKey() == false);
    });
  });

  describe('checkRequest', () => {

    describe('check ip address.', () => {
      it('invalid ip address in fail.', () => {
        auth.deny = ['127.0.0.1', '192.168.1.1'];
        assert(auth.checkRequest(res) == false);
        auth.deny = [''];
      });
      it('valid ip address in success.', () => {
        auth.allow = ['192.168.1.', '127.0.0.1'];
        assert(auth.checkRequest(res) == true);
        auth.allow = [''];
      });
    });

    describe('check api key.', () => {
      it('valid api key in success.', () => {
        auth.apikey = 'foo';
        assert(auth.checkRequest(res) == true);
      });

      it('invalid api key in fail.', () => {
        auth.apikey = 'bar';
        assert(auth.checkRequest(res) == false);
      });

      it('no api key in fail.', () => {
        auth.apikey = '';
        assert(auth.checkRequest(res) == false);
      });
    });
  });

});
