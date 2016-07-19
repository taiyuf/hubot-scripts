'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

var _Context2 = require('./Context');

var _Context3 = _interopRequireDefault(_Context2);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

function _possibleConstructorReturn(self, call) { if (!self) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return call && (typeof call === "object" || typeof call === "function") ? call : self; }

function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function, not " + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; }

var Irc = function (_Context) {
  _inherits(Irc, _Context);

  /**
   * Constructor
   * @param  {Object} robot hubot object.
   *
   * @throws {Error}  arguments error.
   */

  function Irc(robot) {
    _classCallCheck(this, Irc);

    if (!robot) {
      throw new Error('arguments error: robot is not found.');
    }

    var _this = _possibleConstructorReturn(this, Object.getPrototypeOf(Irc).call(this));

    _this.robot = robot;
    _this.msgLabel = 'text';
    _this.lineFeed = "\n";

    _this.htmlFilter = _this.htmlFilter.bind(_this);
    _this.send = _this.send.bind(_this);
    return _this;
  }

  /**
   * Print bold text.
   * @param  {String} str text.
   * @return {Sring}  bold text for irc.
   */


  _createClass(Irc, [{
    key: 'bold',
    value: function bold(str) {
      return str ? "\x02" + str + "\x02" : null;
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
        return "\x1f" + title + "\x1f" + ": " + _url;
      }
    }

    /**
     * Replace html to text.
     * @param  {String} html html.
     * @return {String} text.
     */

  }, {
    key: 'htmlFilter',
    value: function htmlFilter(html) {
      if (!html) {
        return null;
      } else {
        return html.replace(/<br>/g, this.lineFeed).replace(/<br \/>/g, this.lineFeed).replace(/<("[^"]*"|'[^']*'|[^'">])*>/g, '').replace(/^$/g, '').replace(/^${this.lineFeed}$/g, '');
      }
    }

    /**
     * Send message to hubot.
     * @param  {String} target chat room.
     * @param  {String} msg    the message.
     *
     * @throws {Error}  arguments error.
     */

  }, {
    key: 'send',
    value: function send(target, msg) {
      if (!(target && msg)) {
        throw new Error('Irc send: arguments error: target: ' + target + ', msg: ' + msg);
        this.robot.send({ 'room': target }, this.parseType(msg));
      }
    }
  }]);

  return Irc;
}(_Context3.default);

exports.default = Irc;