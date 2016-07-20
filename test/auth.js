import assert from 'power-assert';
import nock from 'nock';
import path from 'path';
import Auth from '../src/Auth';
let auth;

describe('Auth', () => {
  before((done) => {
    auth = new Auth({
      headers: {
        'x-forwarded-for': '127.0.0.1',
        'hubot_http_irc_api_key': 'foo'
      }
    });
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
      auth.deny = '127.0.0.1';
      assert(auth.checkIp() == false);
    });

    it('should deny.', () => {
      auth.deny = null;
      auth.allow = '127.0.0.1';
      assert(auth.checkIp() == true);
      auth.allow = null;
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
        auth.deny = '127.0.0.1';
        assert(auth.checkRequest() == false);
        auth.deny = null;
      });
      it('valid ip address in success.', () => {
        auth.allow = '127.0.0.1';
        assert(auth.checkRequest() == true);
        auth.allow = null;
      });
    });

    describe('check api key.', () => {
      it('valid api key in success.', () => {
        auth.apikey = 'foo';
        assert(auth.checkRequest() == true);
      });

      it('invalid api key in fail.', () => {
        auth.apikey = 'bar';
        assert(auth.checkRequest() == false);
      });

      it('no api key in fail.', () => {
        auth.apikey = null;
        assert(auth.checkRequest() == false);
      });
    });
  });

});
