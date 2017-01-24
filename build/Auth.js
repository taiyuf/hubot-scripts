'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

var Auth = function () {
  /**
   * Constructor
   * @param  {Object} req    the ip address of client.
   * @param  {String} allow  CIDR allowed to request.
   * @param  {String} deny   CIDR denied to request.
   * @param  {String} apikey apikey allowed to request.
   * @throws {Error}  arguments error.
   */
  function Auth(req) {
    var allow = arguments.length <= 1 || arguments[1] === undefined ? '' : arguments[1];

    var _this = this;

    var deny = arguments.length <= 2 || arguments[2] === undefined ? '' : arguments[2];
    var apikey = arguments.length <= 3 || arguments[3] === undefined ? '' : arguments[3];

    _classCallCheck(this, Auth);

    this.name = 'Auth';

    if (!req) {
      throw new Error(this.name + '> arguments error: req is not found.');
    }

    var splitString = function splitString(str) {
      return str.replace(/\s+/g, '').split(',');
    };
    var getRemoteIp = function getRemoteIp(req) {
      if (req.connection && req.connection.remoteAddress) {
        return req.connection.remoteAddress;
      } else if (req.socket && req.socket.remoteAddress) {
        return req.socket.remoteAddress;
      } else if (req.connection && req.connection.socket && req.connection.socket.remoteAddress) {
        return req.connection.socket.remoteAddress;
      } else if (req.headers && req.headers['x-forwarded-for']) {
        return req.headers['x-forwarded-for'];
      } else {
        console.log(_this.name + '> no ip address detected.');
        return null;
      }
    };

    this.req = req;
    this.allow = splitString(allow);
    this.deny = splitString(deny);
    this.apikey = apikey;
    this.remoteIp = getRemoteIp(req);

    this.match = this.match.bind(this);
    this.checkIp = this.checkIp.bind(this);
    this.checkApiKey = this.checkApiKey.bind(this);
    this.checkRequest = this.checkRequest.bind(this);
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
          console.log(this.name + '> ip match: ' + this.remoteIp + ', ' + pattern);
          return true;
        } else {
          console.log(this.name + '> NOT ip match: ' + this.remoteIp + ', ' + pattern);
          return false;
        }
      } else if (pattern.match(/^(\d+\.)+$/)) {
        var re = new RegExp('^' + pattern);
        var result = re.exec(this.remoteIp);
        if (result && result.length != 0) {
          console.log(this.name + '> network match: ' + this.remoteIp + ', ' + pattern);
          return true;
        } else {
          console.log(this.name + '> NOT network match: ' + this.remoteIp + ', ' + pattern);
          return false;
        }
      } else {
        this.error('*** ' + this.name + '> invalid pattern: ' + pattern);
        throw new Error('*** ' + this.name + '> invalid pattern: ' + pattern);
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
      var _this2 = this;

      var flag = void 0;

      if (!(this.deny.length == 1 && this.deny[0] == '')) {
        this.deny.map(function (v, i) {
          if (_this2.match(v)) {
            console.log(_this2.name + '> DENY: ' + _this2.remoteIp);
            flag = false;
            return false;
          }
        });
      }

      if (!(this.allow.length == 1 && this.allow[0] == '')) {
        this.allow.map(function (v, i) {
          if (v == '*') {
            flag = true;
            return true;
          }
          if (_this2.match(v)) {
            console.log(_this2.name + '> ALLOW: ' + _this2.remoteIp + ' <- ' + v);
            flag = true;
            return true;
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
        console.log('match apikey: ' + this.req.headers['hubot_http_irc_api_key']);
        return true;
      } else {
        console.log('NOT match apikey: ' + this.req.headers['hubot_http_irc_api_key']);
        return false;
      }
    }

    /**
     * Check the request is valid.
     * @param  {Object}  req the request object.
     * @return {Boolean} the request is allowed or not.
     *
     * @throws {Error}   arguments error.
     */

  }, {
    key: 'checkRequest',
    value: function checkRequest(res) {
      if (!res) {
        throw new Error(this.name + '> checkRequest req is not found.');
      }

      var result = this.checkIp();
      var resError = function resError() {
        res.writeHead(200, { 'Content-Type': 'text/plain' });
        res.end('Not allowed to access.');
      };

      if (result === true) {
        return true;
      }if (result === false) {
        resError();
        return false;
      } else {
        if (this.checkApiKey()) {
          return true;
        } else {
          resError();
          return false;
        }
      }
    }
  }]);

  return Auth;
}();

exports.default = Auth;