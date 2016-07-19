'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

var _fs = require('fs');

var _fs2 = _interopRequireDefault(_fs);

var _jsYaml = require('js-yaml');

var _jsYaml2 = _interopRequireDefault(_jsYaml);

var _path = require('path');

var _path2 = _interopRequireDefault(_path);

var _superagent = require('superagent');

var _superagent2 = _interopRequireDefault(_superagent);

var _Context2 = require('./Context');

var _Context3 = _interopRequireDefault(_Context2);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

function _possibleConstructorReturn(self, call) { if (!self) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return call && (typeof call === "object" || typeof call === "function") ? call : self; }

function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function, not " + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; }

var Slack = function (_Context) {
  _inherits(Slack, _Context);

  /**
   * Constructor
   * @param  {Object} robot hubot object.
   *
   * @throws {Error}  arguments error.
   */

  function Slack(robot) {
    _classCallCheck(this, Slack);

    if (!robot) {
      throw new Error('arguments error: robot is not found.');
    }

    var _this = _possibleConstructorReturn(this, Object.getPrototypeOf(Slack).call(this));

    _this.robot = robot;
    _this.color = '#aaaaaa';
    var conf = process.env.HUBOT_IRC_INFO;
    _this.info = _jsYaml2.default.safeLoad(_fs2.default.readFileSync(conf));

    _this.buildAttatchment = _this.buildAttatchment.bind(_this);
    _this.send = _this.send.bind(_this);
    return _this;
  }

  /**
   * Print bold text.
   * @param  {String} str text.
   * @return {Sring}  bold text for irc.
   */


  _createClass(Slack, [{
    key: 'bold',
    value: function bold(str) {
      return str ? ' *' + str + '* ' : null;
    }

    /**
     * Print url text.
     * @param  {String} title title of url.
     * @param  {String} url   url.
     * @return {String} url text for irc.
     */

  }, {
    key: 'url',
    value: function url(title, _url) {
      if (!(title && _url)) {
        return null;
      } else {
        return '<' + _url + '|' + title + '>';
      }
    }

    /**
     * Print underline text.
     * @param  {String} str text.
     * @return {Sring}  bold text for irc.
     */

  }, {
    key: 'underline',
    value: function underline(str) {
      return str ? ' *' + str + '* ' : null;
    }

    /**
     * Build attachment for slack.
     * @param  {String} msg  the message.
     * @param  {Object} info the infomation for building attachment.
     * @return {String} attachment for slack.
     */

  }, {
    key: 'buildAttatchment',
    value: function buildAttatchment(msg) {
      var info = arguments.length <= 1 || arguments[1] === undefined ? {} : arguments[1];

      if (!msg) {
        return null;
      }

      var fallback = ['pretext', 'title', 'title_link'];
      var querys = ['pretext', 'title', 'title_link', 'author_name', 'author_link', 'author_icon', 'image_url', 'thumb_url', 'fields', 'color'];

      var at = {};
      var message = this.parseType(msg);

      at.color = info.color ? info.color : this.color;
      at.text = message;
      at.pretext = message;

      var hash = fallback.reduce(function (hash, key) {
        if (info[key]) {
          hash[key] = info[key];
        }
        return hash;
      }, {});

      var f = fallback.reduce(function (array, a) {
        if (info[a]) {
          array.push(info[a]);
        }
        return array;
      }, []);
      f.push(message);
      at.fallback = f.join(' - ');

      at.mrkdwn_in = ['text', 'pretext'];

      querys.map(function (v, i) {
        if (info[v]) {
          at[v] = info[v];
        }
      });

      if (this.debugFlag) {
        this.debug('Slack: attachment: ' + JSON.stringify(at));
      }

      return [at];
    }

    /**
     * Send message to hubot.
     * @param  {String} target  chat room.
     * @param  {String} msg     the message.
     * @param  {Object} info    the infomation for message.
     * @return {Promise} Promis object.
     *
     * @throws {Error}  arguments error.
     */

  }, {
    key: 'send',
    value: function send(target, msg) {
      var _this2 = this;

      var info = arguments.length <= 2 || arguments[2] === undefined ? {} : arguments[2];
      var cb = arguments[3];

      if (!(target && msg)) {
        throw new Error('Irc send: arguments error: target: ' + target + ', msg: ' + msg);
        this.robot.send({ 'room': target }, this.parseType(msg));
      }

      var name = "Slack send";
      var q = {};
      var params = ['color', 'username', 'as_user', 'parse', 'link_name', 'unfurl_links', 'unfurl_media', 'icon_url', 'icon_emoji'];

      q.channel = target;
      q.attachments = this.buildAttatchment(msg, info);

      this.debug(name + '> json: ' + JSON.stringify(q));
      _superagent2.default.post(this.info.webhook_url).send(q).end(function (err, res) {
        if (err || !res.ok) {
          cb && cb(err);
          return;
        }

        _this2.debugFlag && _this2.debug(name + '> body from slack; ' + res.text);
        cb && cb(null, res.text);
      });
    }
  }]);

  return Slack;
}(_Context3.default);

exports.default = Slack;