'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

/**
 * Context
 */

var Context = function () {
  function Context() {
    _classCallCheck(this, Context);

    this.env = process.env.NODE_ENV;
    this.debugFlag = process.env.DEBUG || false;

    // binded funtions
    this.checkType = this.checkType.bind(this);
    this.parseType = this.parseType.bind(this);
    this.debug = this.debug.bind(this);
    this.info = this.info.bind(this);
    this.warn = this.warn.bind(this);
    this.error = this.error.bind(this);
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
   * example:
   *   if (checkType('Array), obj) {
   *     console.log(obj.join(', ));
   *   }
   *
   * @param  {String}  type the type it should be.
   * @param  {Object}  obj  the object you want to know its type.
   * @return {Boolean} true or false.
   */


  _createClass(Context, [{
    key: 'checkType',
    value: function checkType(type, obj) {
      var klass = Object.prototype.toString.call(obj).slice(8, -1);
      return !!obj && klass === type;
    }

    /**
     * @param  {Object} obj something.
     * @return {String} Strings.
     */

  }, {
    key: 'parseType',
    value: function parseType(obj) {
      var str = void 0;

      if (this.checkType('Object', obj)) {
        str = JSON.stringify(obj);
      } else if (this.checkType('Array', obj)) {
        str = obj.join("\n");
      } else if (this.checkType('String', obj)) {
        str = obj;
      } else {
        console.log('*** parseType unknown type: ' + Object.prototype.toString.call(obj).slice(8, -1) + ', ' + obj);
        str = JSON.stringify(obj);
      }

      return str;
    }
  }, {
    key: 'debug',


    /**
     * Write debug log.
     * @param  {Object} obj something.
     * @return {String} output to console.log
     */
    value: function debug(obj) {
      var str = this.parseType(obj);
      this.env != 'production' && console.log('DEBUG: ' + str);
    }
  }, {
    key: 'info',


    /**
     * Write info log.
     * @param  {Object} obj something.
     * @return {String} output to console.log
     */
    value: function info(obj) {
      var str = this.parseType(obj);
      console.log('INFO: ' + str);
    }
  }, {
    key: 'warn',


    /**
     * Write warning log.
     * @param  {Object} obj something.
     * @return {String} output to console.log
     */
    value: function warn(obj) {
      var str = this.parseType(obj);
      console.log('*** WARNING: ' + str);
    }
  }, {
    key: 'error',


    /**
     * Write error log.
     * @param  {Object} obj something.
     * @return {String} output to console.log
     */
    value: function error(obj) {
      var str = this.parseType(obj);
      console.log('*** ERROR: ' + str);
    }
  }]);

  return Context;
}();

exports.default = Context;