'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

var _fs = require('fs');

var _fs2 = _interopRequireDefault(_fs);

var _superagent = require('superagent');

var _superagent2 = _interopRequireDefault(_superagent);

var _Irc = require('./Irc');

var _Irc2 = _interopRequireDefault(_Irc);

var _Slack = require('./Slack');

var _Slack2 = _interopRequireDefault(_Slack);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

/**
 * send
 */
var SendMessage = function () {
  function SendMessage(robot, type) {
    _classCallCheck(this, SendMessage);

    if (!(robot && type)) {
      throw new Error(this.name + ' arguments error: robot: ' + robot + ', type: ' + type);
    }

    this.name = 'SendMessage';

    switch (type) {
      case "irc":
        this.robot = new _Irc2.default(robot);
        break;
      case "slack":
        this.robot = new _Slack2.default(robot);
        break;
      default:
        throw new Error(this.name + ': unknown type: ' + type);
    }
  }

  _createClass(SendMessage, [{
    key: 'send',
    value: function send(target, msg) {
      var _this = this;

      var option = arguments.length <= 2 || arguments[2] === undefined ? {} : arguments[2];

      if (!(target && msg)) {
        throw new Error(this.name + '> arguments error: target: ' + target + ', msg: ' + msg);
      }

      var targets = void 0;
      if (this.robot.checkType('String', target)) {
        targets = [target];
      } else {
        targets = target;
      }

      targets.map(function (v, i) {
        return _this.robot.send(v, msg, option);
      });
    }
  }]);

  return SendMessage;
}();

exports.default = SendMessage;