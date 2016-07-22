import url         from 'url';
import fs          from 'fs';
import yaml        from 'js-yaml';
import querystring from 'querystring';
import path        from 'path';
import request     from 'superagent';
import SendMessage from './SendMessage';
import Auth        from './Auth';

/**
 * Do the job selected by the branch of git on jenkins.
 *
 */

// the type of irc service.
const type       = process.env.HUBOT_IRC_TYPE;

// the configuration file for me.
const configFile = process.env.JENKINS_JOBSELECTOR_CONFIG_FILE;

// the flag whether tell message to irc service.
const sendFlag   = process.env.JENKINS_JOBSELECTOR_SEND_MESSAGE;
const icon       = process.env.JENKINS_JOBSELECTOR_ICON   || null;
const color      = process.env.JENKINS_JOBSELECTOR_COLOR  || '#aaaaaa';
const debug      = process.env.JENKINS_JOBSELECTOR_DEBUG  || process.env.DEBUG || null;
const allow      = process.env.JENKINS_JOBSELECTOR_ALLOW  || '';
const deny       = process.env.JENKINS_JOBSELECTOR_DENY   || '';
const apikey     = process.env.JENKINS_JOBSELECTOR_APIKEY || '';
const ircType    = process.env.HUBOT_IRC_TYPE;
const urlpath    = '/hubot/jenkins-jobselector';
const name       = 'JobSelector';

module.exports = (robot) => {
  const sm   = new SendMessage(robot, type);
  const log  = sm.robot;

  if (!configFile) {
    log.Error(`${name}> no config file.`);
    return;
  }

  const conf = yaml.safeLoad(fs.readFileSync(configFile));
  let service;
  let gitUrl;
  let auth;

  robot.router.post(urlpath, (req, res) => {
    const auth  = new Auth(req, allow, deny, apikey);

    if (!auth.checkRequest(res)) {
      console.log(`not allowed: ${auth.remoteIp}`);
      return;
    }

    log.debug(`data: ${JSON.stringify(req.body)}`);
    const query = querystring.parse(url.parse(req.url).query);
    res.end('OK');

    if (!req.body) {
      throw new Error(`${name}> no body: ${JSON.stringify(req)}`);
    }

    const hook = req.body;

    if (hook.repository.homepage) {
      gitUrl = hook.repository.homepage;
      service = 'gitlab';
    } else {
      gitUrl = hook.repository.html_url;
      service = 'github';
    }

    if (!gitUrl) {
      throw new Error(`${name}> Unknown git repository.`);
    }

    log.debug(`${name}> git url: ${gitUrl}`);

    if (!hook.ref) {
      return;
    }

    const branch  = hook.ref.replace(/refs\/heads\//, '');
    const gitInfo = conf[gitUrl];
    let authInfo;

    if (gitInfo['auth']) {
      authInfo = {};
      authInfo.user = gitInfo['auth']['id'];
      authInfo.pass = gitInfo['auth']['password'];
    } else {
      log.debug(`${name}> No auth infomation.`);
    }

    const jobUrl = gitInfo['jobs'][branch];
    const jobRequest = (url) => {

      if (authInfo) {
        request
          .post(url)
          .auth(authInfo.user, authInfo.pass)
          .end((err, res) => {
            if (err) {
              log.error(`${name}> request error: ${err}`);
              return;
            }
          });
      } else {
        request
          .post(url)
          .end((err, res) => {
            if (err) {
              log.error(`${name}> request error: ${err}`);
              return;
            }
          });
      }
      
      const info = { color: color };
      if (icon) {
        info.icon_url = icon;
      }
      sendFlag && sm.send(gitInfo['target'], `[Jenkins]: The job has started on ${sm.bold(branch)} branch at ${gitUrl}.`, info, (err, res) => {
        if (err) {
          log.error(`${name}> send error: ${err}.`);
        } else {
          log.debug(`${name}> send: ${res}`);
        }
      });
    };

    if (sm.robot.checkType('Array', jobUrl)) {
      jobUrl.map((v, i) => jobRequest(v));
    } else if (sm.robot.checkType('String', jobUrl)) {
      jobRequest(jobUrl);
    } else {
      log.info(`${name}> no jobUrl for ${branch}`);
    }
    
  });
};
