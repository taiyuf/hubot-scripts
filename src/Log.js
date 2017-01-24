import log4js from 'log4js';

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
export default class Log {

  constructor(serverLog, accessLog, errorLog) {

    if (!(serverLog && accessLog && errorLog)) {
      throw new Error(`Log: arguments error: serverLog: ${serverLog}, accessLog: ${accessLog}, errorLog: ${errorLog}`);
    }

    // environment value.
    this.env       = process.env.NODE_ENV || 'production';

    // debug flag.
    this.debugFlag = process.env.DEBUG || false;

    // binded functions.
    this.parse = this.parse.bind(this);

    // the configuration of log4js.
    let logConfig;

    if (this.debugFlag != false) {
      logConfig = {
        appenders: [
          { type: 'console', category: 'server' },
          { type: 'console', category: 'access' },
          { type: 'console', category: 'error' },
        ]
      };
    } else {
      logConfig = {
        appenders: [
          {
            type:     'file',
            filename: serverLog,
            category: 'server'
          },
          {
            type:     'file',
            filename: accessLog,
            category: 'access'
          },
          {
            type:    'file',
            filename: errorLog,
            category: 'error'
          },
        ],
        replaceConsole: true
      };
    }

    log4js.configure(logConfig);

    this.server = log4js.getLogger('server');
    this.access = log4js.getLogger('access');
    this.error  = log4js.getLogger('error');

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
  checkType(type, obj) {
    let klass = Object.prototype.toString.call(obj).slice(8, -1);
    return obj !== undefined && obj !== null && klass === type;
  }

  /**
   * parse the argument and out.
   * @param {Object}  obj something to want to logging.
   * @return {String} the content.
   */
  parse(obj) {
    let log;

    // console.log(`type: ${Object.prototype.toString.call(obj).slice(8, -1)}`);

    if (this.checkType('Object', obj)) {
      try {
        log = JSON.stringify(obj);
      } catch (e) {
        console.error(`Could not JSON stringify: ${e}`);
        log = obj;
      }
    } else if (this.checkType('Array', obj)) {
      log = obj.join('\n');
    } else if (this.checkType('String')) {
      log = obj;
    } else {
      console.log(`Log:parse> unknown log type: ${Object.prototype.toString.call(obj).slice(8, -1)}`);
      log = JSON.stringify(obj);
    }

    return log;
  }
};
