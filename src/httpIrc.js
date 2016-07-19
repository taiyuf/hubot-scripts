import querystring from 'querystring';
import path        from 'path';
import SendMessage from './SendMessage';
import Auth        from './Auth';

/**
 * Simple path to have Hubot echo out anything in the message querystring for a given room.
 * @example
 *   curl http://YOUR_SERVER/http_irc?room=%23foo&message=hoge
 *   curl -X POST --data-urlencode message="hoge hoge." http://YOUR_SERVER/http_irc?room\=foo
 *   curl -X POST --data-urlencode message="hoge hoge." -d  room=foo http://YOUR_SERVER/http_irc?room=#foo
 */
const type        = process.env.HUBOT_IRC_TYPE;
const debug       = process.env.HUBOT_HTTP_IRC_DEBUG;
const api_key     = process.env.HUBOT_HTTP_IRC_API_KEY || null;
const allow       = process.env.HUBOT_HTTP_IRC_ALLOW   || null;
const deny        = process.env.HUBOT_HTTP_IRC_DENY    || null;
const allow_flag  = false;
const urlpath     = "/http_irc";
const name        = 'httpIrc';
const checkReq    = (req, res) => {
  if (!(req && res)) {
    throw new Error(`${name} checkReq: arguments error: req: ${req}, res: ${res}`);
  }
  
  const auth = new Auth(req);
  if (!auth.checkRequest()) {
    res.writeHead(200, {'Content-Type': 'text/plain'});
    res.end('Not allowed to access.');
    return;
  }
};

module.exports = (robot) => {
  const sm = new SendMessage(robot, type);

  robot.router.get(urlpath, (req, res) => {
    checkReq(res, res);

    const query = querystring.parse(req._parsedUrl.query);
    if (!query.room) {
      this.Error(`${name} room is required: query: ${JSON.stringify(query)}`);
      return;
    }
    this.debug(`${name} query: ${JSON.stringify(query)}`);
    
    sm.send([query.room], query.message, query);
    res.writeHead(200, {'Content-Type': 'text/plain'});
    res.end('OK');
    
  });

  robot.router.post(urlpath, (req, res) => {
    checkReq(res, res);

    const query = querystring.parse(req._parsedUrl.query);
    if (!query.room || !req.body.room) {
      this.Error(`${name} room is required: query: ${JSON.stringify(query)}\n${req.body}`);
      return;
    }
    this.debug(`${name} query: ${JSON.stringify(query)}`);
    this.debug(`${name} body: ${JSON.stringify(req.body)}`);

    const room = query.room || req.body.room;

    sm.send([room], query.message, query);
    res.writeHead(200, {'Content-Type': 'text/plain'});
    res.end('OK');
  });
};
