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
const type    = process.env.HUBOT_IRC_TYPE;

// the api key.
const apikey  = process.env.HUBOT_HTTP_IRC_API_KEY || null;

// the network or address allowed.
const allow   = process.env.HUBOT_HTTP_IRC_ALLOW   || null;

// the network or addres denied.
const deny    = process.env.HUBOT_HTTP_IRC_DENY    || null;

// the path of url.
const urlpath = "/http_irc";

// this module name.
const name    = 'httpIrc';

/**
 * Return the response in success.
 * @param  {Object} res the response object.
 * @return {Object} the http response.
 */
const resOk = (res) => {
  if (!res) {
    throw new Error(`responseOk: res is not found.`);
  }

  res.writeHead(200, {'Content-Type': 'text/plain'});
  res.end('OK');
};

module.exports = (robot) => {
  const sm   = new SendMessage(robot, type);
  const log  = sm.robot;

  robot.router.get(`${urlpath}`, (req, res) => {
    const auth  = new Auth(req, allow, deny, apikey);
    const query = querystring.parse(req._parsedUrl.query);

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
    const auth  = new Auth(req, allow, deny, apikey);
    const room  = req.params.room || query.room;
    const query = querystring.parse(req._parsedUrl.query);

    if (!auth.checkRequest(res)) {
      return;
    }

    if (!(req.params.room && query.room)) {
      log.error(`${name} room is required: query: ${JSON.stringify(query)}`);
      return;
    }

    log.debug(`${name} query: ${JSON.stringify(query)}`);

    sm.send(`#${query.room}`, query.message, query, (err, res) => {
      if (err) {
        log.error(err);
      } else {
        log.debug(res);
      }
    });

    resOk(res);
  });

  robot.router.post(urlpath, (req, res) => {
    const auth  = new Auth(req, allow, deny, apikey);
    const query = querystring.parse(req._parsedUrl.query);

    if (!auth.checkRequest(res)) {
      return;
    }

    if (!query.room || !req.body.room) {
      log.error(`${name} room is required: query: ${JSON.stringify(query)}\n${req.body}`);
      return;
    }
    log.debug(`${name} query: ${JSON.stringify(query)}`);
    log.debug(`${name} body: ${JSON.stringify(req.body)}`);

    const room = query.room || req.body.room;

    sm.send(query.room, query.message, query, (err, res) => {
      if (err) {
        log.error(err);
      } else {
        log.debug(res);
      }
    });

    resOk(res);
  });
};
