'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

var Auth = function () {
  /**
   * Constructor
   * @param  {Object} req the ip address of client.
   * @throws {Error}  arguments error.
   */

  function Auth(req) {
    _classCallCheck(this, Auth);

    if (!req) {
      throw new Error('Auth arguments error: req is not found.');
    }

    this.req = req;
    this.name = 'Auth';
    this.allow = process.env.HUBOT_HTTP_IRC_ALLOW || null;
    this.deny = process.env.HUBOT_HTTP_IRC_DENY || null;
    this.apikey = process.env.HUBOT_HTTP_IRC_API_KEY || null;
    this.remoteIp = req.headers && req.headers['x-forwarded-for'] || req.connection.remoteAddress || req.socket.remoteAddress || req.connection.socket.remoteAddress;

    this.match = this.match.bind(this);
    this.checkIp = this.checkIp.bind(this);
    this.checkApiKey = this.checkApiKey.bind(this);
    this.checkRequest = this.checkRequest.bind(this);

    console.log('remote ip: ' + this.remoteIp);
  }

  /**
   * Check the ip match the pattern.
   * @param  {String}  pattern the pattern of ip.
   * @return {Boolean} if ip match or not.
   *
   * @throws {Error}   arguments error.
   */


  _createClass(Auth, [{
    key: 'match',
    value: function match(pattern) {
      if (!pattern) {
        throw new Error(this.name + ' match> arguments error.');
      }

      if (pattern.match(/^\d+\.\d+\.\d+\.\d+$/)) {
        if (this.remoteIp == pattern) {
          console.log('match: ' + this.remoteIp + ', ' + pattern);
          return true;
        } else {
          console.log('NOT match: ' + this.remoteIp + ', ' + pattern);
          return false;
        }
      } else if (pattern.match(/^(\d+\.)+$/)) {
        var re = new RegExp('^' + pattern);
        var result = re.exec(this.remoteIp);
        if (result && result.length != 0) {
          console.log('match: ' + this.remoteIp + ', ' + pattern);
          return true;
        } else {
          console.log('NOT match: ' + this.remoteIp + ', ' + pattern);
          return false;
        }
      } else {
        this.error('*** invalid pattern: ' + pattern);
        throw new Error('*** invalid pattern: ' + pattern);
      }
    }

    /**
     * Check the remote ip address which is allowed.
     * @example
     *   if (!this.checkIp(req)) {
     *     console.log(`Not allowed.);
     *     return;
     *   }
     *
     * @return {Boolean} if allowed ip or not.
     *
     * @throws {Error}   arguments error.
     */

  }, {
    key: 'checkIp',
    value: function checkIp() {
      var _this = this;

      var flag = void 0;

      if (!!this.deny) {
        var denyIps = this.deny.split(',');
        denyIps.map(function (v, i) {
          if (_this.match(_this.remoteIp, v)) {
            console.log('DENY: ' + _this.remoteIp);
            flag = false;
          }
        });
      }

      if (!!this.allow) {
        var allowIps = this.allow.split(',');
        allowIps.map(function (v, i) {
          if (_this.match(_this.remoteIp, v)) {
            console.log('ALLOW: ' + _this.remoteIp);
            flag = true;
          }
        });
      }

      return flag;
    }

    /**
     * Check the api_key from header of request.
     * @return {Boolean} if the apikey match or not.
     *
     * @throws {Error}   arguments error.
     */

  }, {
    key: 'checkApiKey',
    value: function checkApiKey() {
      if (this.req.headers && this.req.headers['hubot_http_irc_api_key'] && this.apikey == this.req.headers['hubot_http_irc_api_key']) {
        return true;
      } else {
        return false;
      }
    }

    /**
     * Check the request is valid.
     * @return {Boolean} the request is allowed or not.
     *
     * @throws {Error}   arguments error.
     */

  }, {
    key: 'checkRequest',
    value: function checkRequest() {
      var result = this.checkIp();
      if (result === true) {
        return true;
      } else if (result === false) {
        return false;
      } else {
        return this.checkApiKey();
      }
    }
  }]);

  return Auth;
}();

exports.default = Auth;