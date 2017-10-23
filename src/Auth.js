/* @flow */
export default class Auth {

  name:         string;
  req:          any;
  allow:        Array<string>;
  deny:         Array<string>;
  apikey:       string;
  remoteIp:     string;
  match:        (pattern: string) => any;
  checkIp:      () => any;
  checkApiKey:  () => any;
  checkRequest: (res: any) => any;

  /**
   * Constructor
   * @param  {Object}        req    the ip address of client.
   * @param  {Array<String>} allow  CIDR allowed to request.
   * @param  {Array<String>} deny   CIDR denied to request.
   * @param  {String}        apikey apikey allowed to request.
   * @throws {Error}         arguments error.
   */
  constructor(req: any, allow: string='', deny: string='', apikey: string=''): void {
    this.name = 'Auth';

    if (!req) {
      throw new Error(`${this.name}> arguments error: req is not found.`);
    }

    const splitString: (str: string) => any = (str: string): Array<string> => str.replace(/\s+/g, '').split(',');
    const getRemoteIp: (req: any) => any = (req: any): string => {
      if (req.connection && req.connection.remoteAddress) {
        return req.connection.remoteAddress;
      } else if (req.socket && req.socket.remoteAddress) {
        return req.socket.remoteAddress;
      } else if (req.connection && req.connection.socket && req.connection.socket.remoteAddress) {
        return req.connection.socket.remoteAddress;
      } else if (req.headers && req.headers['x-forwarded-for']) {
        return  req.headers['x-forwarded-for'];
      } else {
        console.log(`${this.name}> no ip address detected.`);
        return '';
      }
    };

    this.req          = req;
    this.allow        = splitString(allow);
    this.deny         = splitString(deny);
    this.apikey       = apikey;
    this.remoteIp     = getRemoteIp(req);

    this.match        = this.match.bind(this);
    this.checkIp      = this.checkIp.bind(this);
    this.checkApiKey  = this.checkApiKey.bind(this);
    this.checkRequest = this.checkRequest.bind(this);
  }

  /**
   * Check the ip match the pattern.
   * @param  {String}  pattern the pattern of ip.
   * @return {Boolean} if ip match or not.
   *
   * @throws {Error}   arguments error.
   */
  match(pattern: string): boolean {
    if (!pattern) {
      throw new Error(`${this.name} match> arguments error.`);
    }

    if (pattern.match(/^\d+\.\d+\.\d+\.\d+$/)) {
      if (this.remoteIp == pattern) {
        console.log(`${this.name}> ip match: ${this.remoteIp}, ${pattern}`);
        return true;
      } else {
        console.log(`${this.name}> NOT ip match: ${this.remoteIp}, ${pattern}`);
        return false;
      }
    } else if (pattern.match(/^(\d+\.)+$/)) {
      const re = new RegExp(`^${pattern}`);
      const result = re.exec(this.remoteIp);
      if (result && result.length != 0) {
        console.log(`${this.name}> network match: ${this.remoteIp}, ${pattern}`);
        return true;
      } else {
        console.log(`${this.name}> NOT network match: ${this.remoteIp}, ${pattern}`);
        return false;
      }
    } else {
      console.error(`*** ${this.name}> invalid pattern: ${pattern}`);
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
  checkIp(): boolean {

    let flag: boolean = false;

    if (!(this.deny.length == 1 && this.deny[0] == '')) {
      this.deny.map((v, i) => {
        if (this.match(v)) {
          console.log(`${this.name}> DENY: ${this.remoteIp}`);
          flag = false;
          return false;
        }
      });
    }

    if (!(this.allow.length == 1 && this.allow[0] == '')) {
      this.allow.map((v, i) => {
        if (v == '*') {
          flag = true;
          return true;
        }
        if (this.match(v)) {
          console.log(`${this.name}> ALLOW: ${this.remoteIp} <- ${v}`);
          flag = true;
          return true;
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
  checkApiKey(): boolean {
    if (this.req.headers &&
        this.req.headers['hubot_http_irc_api_key'] &&
        this.apikey == this.req.headers['hubot_http_irc_api_key']) {
      console.log(`match apikey: ${this.req.headers['hubot_http_irc_api_key']}`);
      return true;
    } else {
      console.log(`NOT match apikey: ${this.req.headers['hubot_http_irc_api_key']}`);
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
  checkRequest(res: any): boolean {
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
      if (this.checkApiKey()) {
        return true;
      } else {
        resError();
        return false;
      }
    }
  }

}
