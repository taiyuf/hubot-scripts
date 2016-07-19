'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

var _log4js = require('log4js');

var _log4js2 = _interopRequireDefault(_log4js);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

/**
 * Logger for server side by javascript. if you want to write to console, add environment value, DEBUG=true.
 *
 * @example
 *   import Log from './Log';
 *   const log = new Log(config.log.server, config.log.access, config.log.error);
 *   log.server.debug(`foo`);
 *
 * @param  {String} serverLog the path of server log.
 * @param  {String} accessLog the path of access log.
 * @param  {String} errorLog  the path or error log.
 *
 * @throws {Error}  arguments error.
 */

var Log = function () {
  function Log(serverLog, accessLog, errorLog) {
    _classCallCheck(this, Log);

    if (!(serverLog && accessLog && errorLog)) {
      throw new Error('Log: arguments error: serverLog: ' + serverLog + ', accessLog: ' + accessLog + ', errorLog: ' + errorLog);
    }

    // environment value.
    this.env = process.env.NODE_ENV || 'production';

    // debug flag.
    this.debugFlag = process.env.DEBUG || false;

    // binded functions.
    this.parse = this.parse.bind(this);

    // the configuration of log4js.
    var logConfig = void 0;

    if (this.debugFlag != false) {
      logConfig = {
        appenders: [{ type: 'console', category: 'server' }, { type: 'console', category: 'access' }, { type: 'console', category: 'error' }]
      };
    } else {
      logConfig = {
        appenders: [{
          type: 'file',
          filename: serverLog,
          category: 'server'
        }, {
          type: 'file',
          filename: accessLog,
          category: 'access'
        }, {
          type: 'file',
          filename: errorLog,
          category: 'error'
        }],
        replaceConsole: true
      };
    }

    _log4js2.default.configure(logConfig);

    this.server = _log4js2.default.getLogger('server');
    this.access = _log4js2.default.getLogger('access');
    this.error = _log4js2.default.getLogger('error');

    if (this.env == 'production') {
      this.server.setLevel('info');
      this.access.setLevel('info');
      this.error.setLevel('all');
    } else {
      this.server.setLevel('all');
      this.access.setLevel('all');
      this.error.setLevel('all');
    }
  }

  /**
   * Check type of argument.
   *
   * available type:
   *
   * - String
   * - Number
   * - Boolean
   * - Date
   * - Error
   * - Array
   * - Function
   * - RegExp
   * - Object
   *
   * @example
   *   if (checkType('Array'), obj) {
   *     console.log(obj.join(', '));
   *   }
   *
   * @param  {String}  type the type it should be.
   * @param  {Object}  obj  the object you want to know its type.
   * @return {Boolean} true or false.
   */


  _createClass(Log, [{
    key: 'checkType',
    value: function checkType(type, obj) {
      var klass = Object.prototype.toString.call(obj).slice(8, -1);
      return obj !== undefined && obj !== null && klass === type;
    }

    /**
     * parse the argument and out.
     * @param {Object}  obj something to want to logging.
     * @return {String} the content.
     */

  }, {
    key: 'parse',
    value: function parse(obj) {
      var log = void 0;

      // console.log(`type: ${Object.prototype.toString.call(obj).slice(8, -1)}`);

      if (this.checkType('Object', obj)) {
        try {
          log = JSON.stringify(obj);
        } catch (e) {
          console.error('Could not JSON stringify: ' + e);
          log = obj;
        }
      } else if (this.checkType('Array', obj)) {
        log = obj.join('\n');
      } else if (this.checkType('String')) {
        log = obj;
      } else {
        console.log('Log:parse> unknown log type: ' + Object.prototype.toString.call(obj).slice(8, -1));
        log = JSON.stringify(obj);
      }

      return log;
    }
  }]);

  return Log;
}();

exports.default = Log;
;