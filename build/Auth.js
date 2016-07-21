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
    var deny = arguments.length <= 2 || arguments[2] === undefined ? '' : arguments[2];
    var apikey = arguments.length <= 3 || arguments[3] === undefined ? '' : arguments[3];

    _classCallCheck(this, Auth);

    if (!req) {
      throw new Error('Auth arguments error: req is not found.');
    }

    var splitString = function splitString(str) {
      return str.replace(/\s+/g, '').split(',');
    };

    this.req = req;
    this.name = 'Auth';
    this.allow = splitString(allow);
    this.deny = splitString(deny);
    this.apikey = apikey;
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
          console.log(this.name + '> match: ' + this.remoteIp + ', ' + pattern);
          return true;
        } else {
          console.log(this.name + '> NOT match: ' + this.remoteIp + ', ' + pattern);
          return false;
        }
      } else if (pattern.match(/^(\d+\.)+$/)) {
        var re = new RegExp('^' + pattern);
        var result = re.exec(this.remoteIp);
        if (result && result.length != 0) {
          console.log(this.name + '> match: ' + this.remoteIp + ', ' + pattern);
          return true;
        } else {
          console.log(this.name + '> NOT match: ' + this.remoteIp + ', ' + pattern);
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
      var _this = this;

      var flag = void 0;

      if (!(this.deny.length == 1 && this.deny[0] == '')) {
        this.deny.map(function (v, i) {
          if (_this.match(_this.remoteIp, v)) {
            console.log(_this.name + '> DENY: ' + _this.remoteIp);
            flag = false;
          }
        });
      }

      if (!(this.allow.length == 1 && this.allow[0] == '')) {
        this.allow.map(function (v, i) {
          if (_this.match(_this.remoteIp, v)) {
            console.log(_this.name + '> ALLOW: ' + _this.remoteIp);
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
        if (!this.checkApiKey()) {
          resError();
          return false;
        } else {
          return true;
        }
      }
    }
  }]);

  return Auth;
}();

exports.default = Auth;