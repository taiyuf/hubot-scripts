'use strict';

var _querystring = require('querystring');

var _querystring2 = _interopRequireDefault(_querystring);

var _path = require('path');

var _path2 = _interopRequireDefault(_path);

var _SendMessage = require('./SendMessage');

var _SendMessage2 = _interopRequireDefault(_SendMessage);

var _Auth = require('./Auth');

var _Auth2 = _interopRequireDefault(_Auth);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

/**
 * Simple path to have Hubot echo out anything in the message querystring for a given room.
 * @example
 *   curl http://YOUR_SERVER/http_irc?room=%23foo&message=hoge
 *   curl http://YOUR_SERVER/http_irc/foo?message=hoge
 *   curl -X POST --data-urlencode message="hoge hoge." http://YOUR_SERVER/http_irc?room\=foo
 *   curl -X POST --data-urlencode message="hoge hoge." -d  room=foo http://YOUR_SERVER/http_irc?room=#foo
 */

// the type of irc.
var type = process.env.HUBOT_IRC_TYPE;

// the api key.
var apikey = process.env.HUBOT_HTTP_IRC_API_KEY || '';

// the network or address allowed.
var allow = process.env.HUBOT_HTTP_IRC_ALLOW || '';

// the network or addres denied.
var deny = process.env.HUBOT_HTTP_IRC_DENY || '';

// the path of url.
var urlpath = "/http_irc";

// this module name.
var name = 'httpIrc';

/**
 * Return the response in success.
 * @param  {Object} res the response object.
 * @return {Object} the http response.
 */
var resOk = function resOk(res) {
  if (!res) {
    throw new Error('responseOk: res is not found.');
  }

  res.writeHead(200, { 'Content-Type': 'text/plain' });
  res.end('OK');
};

module.exports = function (robot) {
  var sm = new _SendMessage2.default(robot, type);
  var log = sm.robot;

  robot.router.get('' + urlpath, function (req, res) {
    var auth = new _Auth2.default(req, allow, deny, apikey);
    var query = _querystring2.default.parse(req._parsedUrl.query);

    if (!auth.checkRequest(res)) {
      return;
    }

    if (!query.room) {
      log.error(name + ' room is required: query: ' + JSON.stringify(query));
      return;
    }

    log.debug(name + ' query: ' + JSON.stringify(query));

    sm.send(query.room, query.message, query, function (err, res) {
      if (err) {
        log.error(err);
      } else {
        log.debug(res);
      }
    });

    resOk(res);
  });

  robot.router.get(urlpath + '/:room', function (req, res) {
    var auth = new _Auth2.default(req, allow, deny, apikey);
    var room = req.params.room || query.room;
    var query = _querystring2.default.parse(req._parsedUrl.query);

    if (!auth.checkRequest(res)) {
      return;
    }

    if (!(req.params.room && query.room)) {
      log.error(name + ' room is required: query: ' + JSON.stringify(query));
      return;
    }

    log.debug(name + ' query: ' + JSON.stringify(query));

    sm.send('#' + query.room, query.message, query, function (err, res) {
      if (err) {
        log.error(err);
      } else {
        log.debug(res);
      }
    });

    resOk(res);
  });

  robot.router.post(urlpath, function (req, res) {
    var auth = new _Auth2.default(req, allow, deny, apikey);
    var query = _querystring2.default.parse(req._parsedUrl.query);

    if (!auth.checkRequest(res)) {
      return;
    }

    if (!(query.room || req.body.room)) {
      log.error(name + ' room is required: query: ' + JSON.stringify(query) + '\n' + JSON.stringify(req.body));
      return;
    }
    log.debug(name + ' query: ' + JSON.stringify(query));
    log.debug(name + ' body: ' + JSON.stringify(req.body));

    var room = query.room || req.body.room;
    var message = query.message || req.body.message;

    sm.send(room, message, query, function (err, res) {
      if (err) {
        log.error(err);
      } else {
        log.debug(res);
      }
    });

    resOk(res);
  });
};