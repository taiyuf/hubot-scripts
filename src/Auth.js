export default class Auth {
  /**
   * Constructor
   * @param  {Object} req    the ip address of client.
   * @param  {String} allow  CIDR allowed to request.
   * @param  {String} deny   CIDR denied to request.
   * @param  {String} apikey apikey allowed to request.
   * @throws {Error}  arguments error.
   */
  constructor(req, allow='', deny='', apikey='') {
    if (!req) {
      throw new Error(`Auth arguments error: req is not found.`);
    }

    const splitString = (str) => str.replace(/\s+/g, '').split(',');

    this.req          = req;
    this.name         = 'Auth';
    this.allow        = splitString(allow);
    this.deny         = splitString(deny);
    this.apikey       = apikey;
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
        console.log(`${this.name}> match: ${this.remoteIp}, ${pattern}`);
        return true;
      } else {
        console.log(`${this.name}> NOT match: ${this.remoteIp}, ${pattern}`);
        return false;
      }
    } else if (pattern.match(/^(\d+\.)+$/)) {
      const re = new RegExp(`^${pattern}`);
      const result = re.exec(this.remoteIp);
      if (result && result.length != 0) {
        console.log(`${this.name}> match: ${this.remoteIp}, ${pattern}`);
        return true;
      } else {
        console.log(`${this.name}> NOT match: ${this.remoteIp}, ${pattern}`);
        return false;
      }
    } else {
      this.error(`*** ${this.name}> invalid pattern: ${pattern}`);
      throw new Error(`*** ${this.name}> invalid pattern: ${pattern}`);
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

    if (!(this.deny.length == 1 && this.deny[0] == '')) {
      this.deny.map((v, i) => {
        if (this.match(this.remoteIp, v)) {
          console.log(`${this.name}> DENY: ${this.remoteIp}`);
          flag = false;
        }
      });
    }

    if (!(this.allow.length == 1 && this.allow[0] == '')) {
      this.allow.map((v, i) => {
        if (this.match(this.remoteIp, v)) {
          console.log(`${this.name}> ALLOW: ${this.remoteIp}`);
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
   * @param  {Object}  req the request object.
   * @return {Boolean} the request is allowed or not.
   *
   * @throws {Error}   arguments error.
   */
  checkRequest(res) {
    if (!res) {
      throw new Error(`${this.name}> checkRequest req is not found.`);
    }

    const result = this.checkIp();
    const resError = () => {
      res.writeHead(200, {'Content-Type': 'text/plain'});
      res.end('Not allowed to access.');
    };

    if (result === true) {
      return true;
    } if (result === false) {
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

}
