export default class Auth {
  /**
   * Constructor
   * @param  {Object} req the ip address of client.
   * @throws {Error}  arguments error.
   */
  constructor(req) {
    if (!req) {
      throw new Error(`Auth arguments error: req is not found.`);
    }

    this.req          = req;
    this.name         = 'Auth';
    this.allow        = process.env.HUBOT_HTTP_IRC_ALLOW   || null;
    this.deny         = process.env.HUBOT_HTTP_IRC_DENY    || null;
    this.apikey       = process.env.HUBOT_HTTP_IRC_API_KEY || null;
    this.remoteIp     = req.headers && req.headers['x-forwarded-for'] ||
      req.connection.remoteAddress ||
      req.socket.remoteAddress ||
      req.connection.socket.remoteAddress;

    this.match        = this.match.bind(this);
    this.checkIp      = this.checkIp.bind(this);
    this.checkApiKey  = this.checkApiKey.bind(this);
    this.checkRequest = this.checkRequest.bind(this);

    console.log(`remote ip: ${this.remoteIp}`);
  }

  /**
   * Check the ip match the pattern.
   * @param  {String}  pattern the pattern of ip.
   * @return {Boolean} if ip match or not.
   *
   * @throws {Error}   arguments error.
   */
  match(pattern) {
    if (!pattern) {
      throw new Error(`${this.name} match> arguments error.`);
    }

    if (pattern.match(/^\d+\.\d+\.\d+\.\d+$/)) {
      if (this.remoteIp == pattern) {
        console.log(`match: ${this.remoteIp}, ${pattern}`);
        return true;
      } else {
        console.log(`NOT match: ${this.remoteIp}, ${pattern}`);
        return false;
      }
    } else if (pattern.match(/^(\d+\.)+$/)) {
      const re = new RegExp(`^${pattern}`);
      const result = re.exec(this.remoteIp);
      if (result && result.length != 0) {
        console.log(`match: ${this.remoteIp}, ${pattern}`);
        return true;
      } else {
        console.log(`NOT match: ${this.remoteIp}, ${pattern}`);
        return false;
      }
    } else {
      this.error(`*** invalid pattern: ${pattern}`);
      throw new Error(`*** invalid pattern: ${pattern}`);
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
  checkIp() {
    let flag;

    if (!!this.deny) {
      const denyIps = this.deny.split(',');
      denyIps.map((v, i) => {
        if (this.match(this.remoteIp, v)) {
          console.log(`DENY: ${this.remoteIp}`);
          flag = false;
        }
      });
    }

    if (!!this.allow) {
      const allowIps = this.allow.split(',');
      allowIps.map((v, i) => {
        if (this.match(this.remoteIp, v)) {
          console.log(`ALLOW: ${this.remoteIp}`);
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
  checkApiKey() {
    if (this.req.headers &&
        this.req.headers['hubot_http_irc_api_key'] &&
        this.apikey == this.req.headers['hubot_http_irc_api_key']) {
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
  checkRequest() {
    const result = this.checkIp();
    if (result === true) {
      return true;
    } else if (result === false) {
      return false;
    } else {
      return this.checkApiKey();
    }
  }

}
