'use strict';

var _url = require('url');

var _url2 = _interopRequireDefault(_url);

var _fs = require('fs');

var _fs2 = _interopRequireDefault(_fs);

var _jsYaml = require('js-yaml');

var _jsYaml2 = _interopRequireDefault(_jsYaml);

var _querystring = require('querystring');

var _querystring2 = _interopRequireDefault(_querystring);

var _path = require('path');

var _path2 = _interopRequireDefault(_path);

var _superagent = require('superagent');

var _superagent2 = _interopRequireDefault(_superagent);

var _SendMessage = require('./SendMessage');

var _SendMessage2 = _interopRequireDefault(_SendMessage);

var _Auth = require('./Auth');

var _Auth2 = _interopRequireDefault(_Auth);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

/**
 * Do the job selected by the branch of git on jenkins.
 *
 */

// the type of irc service.
var type = process.env.HUBOT_IRC_TYPE;

// the configuration file for me.
var configFile = process.env.JENKINS_JOBSELECTOR_CONFIG_FILE;

// the flag whether tell message to irc service.
var sendFlag = process.env.JENKINS_JOBSELECTOR_SEND_MESSAGE;
var icon = process.env.JENKINS_JOBSELECTOR_ICON || null;
var color = process.env.JENKINS_JOBSELECTOR_COLOR || '#aaaaaa';
var debug = process.env.JENKINS_JOBSELECTOR_DEBUG || process.env.DEBUG || null;
var allow = process.env.JENKINS_JOBSELECTOR_ALLOW || '';
var deny = process.env.JENKINS_JOBSELECTOR_DENY || '';
var apikey = process.env.JENKINS_JOBSELECTOR_APIKEY || '';
var ircType = process.env.HUBOT_IRC_TYPE;
var urlpath = '/hubot/jenkins-jobselector';
var name = 'JobSelector';

module.exports = function (robot) {
  var sm = new _SendMessage2.default(robot, type);
  var log = sm.robot;

  if (!configFile) {
    log.Error(name + '> no config file.');
    return;
  }

  var conf = _jsYaml2.default.safeLoad(_fs2.default.readFileSync(configFile));
  var service = void 0;
  var gitUrl = void 0;
  var auth = void 0;

  robot.router.post(urlpath, function (req, res) {
    var auth = new _Auth2.default(req, allow, deny, apikey);

    if (!auth.checkRequest(res)) {
      console.log('not allowed: ' + auth.remoteIp);
      return;
    }

    log.debug('data: ' + JSON.stringify(req.body));
    var query = _querystring2.default.parse(_url2.default.parse(req.url).query);
    res.end('OK');

    if (!req.body) {
      throw new Error(name + '> no body: ' + JSON.stringify(req));
    }

    var hook = req.body;

    if (hook.repository.homepage) {
      gitUrl = hook.repository.homepage;
      service = 'gitlab';
    } else {
      gitUrl = hook.repository.html_url;
      service = 'github';
    }

    if (!gitUrl) {
      throw new Error(name + '> Unknown git repository.');
    }

    log.debug(name + '> git url: ' + gitUrl);

    if (!hook.ref) {
      return;
    }

    var branch = hook.ref.replace(/refs\/heads\//, '');
    var gitInfo = conf[gitUrl];
    var authInfo = void 0;

    if (gitInfo['auth']) {
      authInfo = {};
      authInfo.user = gitInfo['auth']['id'];
      authInfo.pass = gitInfo['auth']['password'];
    } else {
      log.debug(name + '> No auth infomation.');
    }

    var jobUrl = gitInfo['jobs'][branch];
    var jobRequest = function jobRequest(url) {

      if (authInfo) {
        _superagent2.default.post(url).auth(authInfo.user, authInfo.pass).end(function (err, res) {
          if (err) {
            log.error(name + '> request error: ' + err);
            return;
          }
        });
      } else {
        _superagent2.default.post(url).end(function (err, res) {
          if (err) {
            log.error(name + '> request error: ' + err);
            return;
          }
        });
      }

      var info = { color: color };
      if (icon) {
        info.icon_url = icon;
      }
      sendFlag && sm.send(gitInfo['target'], '[Jenkins]: The job has started on ' + sm.bold(branch) + ' branch at ' + gitUrl + '.', info, function (err, res) {
        if (err) {
          log.error(name + '> send error: ' + err + '.');
        } else {
          log.debug(name + '> send: ' + res);
        }
      });
    };

    if (sm.robot.checkType('Array', jobUrl)) {
      jobUrl.map(function (v, i) {
        return jobRequest(v);
      });
    } else if (sm.robot.checkType('String', jobUrl)) {
      jobRequest(jobUrl);
    } else {
      log.info(name + '> no jobUrl for ' + branch);
    }
  });
};