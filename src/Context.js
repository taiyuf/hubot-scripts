/**
 * Context
 */
export default class Context {

  constructor() {
    this.env        = process.env.NODE_ENV;
    this.debugFlag  = process.env.DEBUG || false;

    // binded funtions
    this.checkType = this.checkType.bind(this);
    this.parseType = this.parseType.bind(this);
    this.debug     = this.debug.bind(this);
    this.info      = this.info.bind(this);
    this.warn      = this.warn.bind(this);
    this.error     = this.error.bind(this);
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
  checkType(type, obj) {
    let klass = Object.prototype.toString.call(obj).slice(8, -1);
    return !!obj && klass === type;
  }

  /**
   * @param  {Object} obj something.
   * @return {String} Strings.
   */
  parseType(obj) {
    let str;

    if(this.checkType('Object', obj)) {
      str = JSON.stringify(obj);
    } else if (this.checkType('Array', obj)) {
      str = obj.join("\n");
    } else if (this.checkType('String', obj)) {
      str = obj;
    } else {
      console.log(`*** parseType unknown type: ${Object.prototype.toString.call(obj).slice(8, -1)}, ${obj}`);
      str = JSON.stringify(obj);
    }

    return str;
  };

  /**
   * Write debug log.
   * @param  {Object} obj something.
   * @return {String} output to console.log
   */
  debug(obj) {
    const str = this.parseType(obj);
    this.env != 'production' && console.log(`DEBUG: ${str}`);
  };

  /**
   * Write info log.
   * @param  {Object} obj something.
   * @return {String} output to console.log
   */
  info(obj) {
    const str = this.parseType(obj);
    console.log(`INFO: ${str}`);
  };

  /**
   * Write warning log.
   * @param  {Object} obj something.
   * @return {String} output to console.log
   */
  warn(obj) {
    const str = this.parseType(obj);
    console.log(`*** WARNING: ${str}`);
  };

  /**
   * Write error log.
   * @param  {Object} obj something.
   * @return {String} output to console.log
   */
  error(obj) {
    const str = this.parseType(obj);
    console.log(`*** ERROR: ${str}`);
  };

}
