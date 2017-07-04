/* @flow */
import querystring from 'querystring';
import path        from 'path';
import SendMessage from './SendMessage';
import Auth        from './Auth';

/**
 * Simple path to have Hubot echo out anything in the message querystring for a given room.
 * @example
 *   curl http://YOUR_SERVER/http_irc?room=%23foo&message=hoge
 *   curl http://YOUR_SERVER/http_irc/foo?message=hoge
 *   curl -X POST --data-urlencode message="hoge hoge." http://YOUR_SERVER/http_irc?room\=foo
 *   curl -X POST --data-urlencode message="hoge hoge." -d  room=foo http://YOUR_SERVER/http_irc?room=#foo
 */

// the type of irc.
const type: string    = process.env.HUBOT_IRC_TYPE || 'slack';

// the api key.
const apikey: string  = process.env.HUBOT_HTTP_IRC_API_KEY || '';

// the network or address allowed.
const allow: string   = process.env.HUBOT_HTTP_IRC_ALLOW   || '';

// the network or addres denied.
const deny: string    = process.env.HUBOT_HTTP_IRC_DENY    || '';

// the path of url.
const urlpath: string = "/http_irc";

// this module name.
const name: string    = 'httpIrc';

/**
 * Return the response in success.
 * @param  {Object} res the response object.
 * @return {Object} the http response.
 */
const resOk = (res: any): any => {
  if (!res) {
    throw new Error(`responseOk: res is not found.`);
  }

  res.writeHead(200, {'Content-Type': 'text/plain'});
  res.end('OK');
};

module.exports = (robot: any) => {
  const sm: any   = new SendMessage(robot, type);
  const log: any  = sm.robot;

  robot.router.get(`${urlpath}`, (req: any, res: any) => {
    const auth: any  = new Auth(req, allow, deny, apikey);
    const query: any = querystring.parse(req._parsedUrl.query);

    if (!auth.checkRequest(res)) {
      return;
    }

    if (!query.room) {
      log.error(`${name} room is required: query: ${JSON.stringify(query)}`);
      return;
    }

    log.debug(`${name} query: ${JSON.stringify(query)}`);

    sm.send(query.room, query.message, query, (err, res) => {
      if (err) {
        log.error(err);
      } else {
        log.debug(res);
      }
    });

    resOk(res);
  });

  robot.router.get(`${urlpath}/:room`, (req, res) => {
    const auth: any    = new Auth(req, allow, deny, apikey);
    const query: any   = querystring.parse(req._parsedUrl.query);
    const room: string = req.params.room || query.room;

    if (!auth.checkRequest(res)) {
      return;
    }

    if (!(req.params.room && query.room)) {
      log.error(`${name} room is required: query: ${JSON.stringify(query)}`);
      return;
    }

    log.debug(`${name} query: ${JSON.stringify(query)}`);

    sm.send(`#${room}`, query.message, query, (err, res) => {
      if (err) {
        log.error(err);
      } else {
        log.debug(res);
      }
    });

    resOk(res);
  });

  robot.router.post(urlpath, (req, res) => {
    const auth: any  = new Auth(req, allow, deny, apikey);
    const query: any = querystring.parse(req._parsedUrl.query);

    if (!auth.checkRequest(res)) {
      return;
    }

    if (!(query.room || req.body.room)) {
      log.error(`${name} room is required: query: ${JSON.stringify(query)}\n${JSON.stringify(req.body)}`);
      return;
    }
    log.debug(`${name} query: ${JSON.stringify(query)}`);
    log.debug(`${name} body: ${JSON.stringify(req.body)}`);

    const room : string   = query.room || req.body.room;
    const message: string = query.message || req.body.message;

    sm.send(room, message, query, (err, res) => {
      if (err) {
        log.error(err);
      }

      log.debug(res);
    });

    resOk(res);
  });
};
