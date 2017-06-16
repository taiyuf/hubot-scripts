/* @flow */
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
const type: string       = process.env.HUBOT_IRC_TYPE || 'slack';

// the configuration file for me.
const configFile: string = process.env.JENKINS_JOBSELECTOR_CONFIG_FILE || '';

// the flag whether tell message to irc service.
const sendFlag: string   = process.env.JENKINS_JOBSELECTOR_SEND_MESSAGE || '';
const icon: string       = process.env.JENKINS_JOBSELECTOR_ICON   || '';
const color: string      = process.env.JENKINS_JOBSELECTOR_COLOR  || '#aaaaaa';
const debug: string      = process.env.JENKINS_JOBSELECTOR_DEBUG  || process.env.DEBUG || '';
const allow: string      = process.env.JENKINS_JOBSELECTOR_ALLOW  || '';
const deny: string       = process.env.JENKINS_JOBSELECTOR_DENY   || '';
const apikey: string     = process.env.JENKINS_JOBSELECTOR_APIKEY || '';
const urlpath: string    = '/hubot/jenkins-jobselector';
const name: string       = 'JobSelector';

module.exports = (robot: any) => {

  if (!configFile) {
    throw new Error(`*** Please set: configFile.`);
  }


  const sm: any   = new SendMessage(robot, type);
  const log: any  = sm.robot;

  if (!configFile) {
    log.error(`${name}> no config file.`);
    return;
  }

  const conf = yaml.safeLoad(fs.readFileSync(configFile));
  let service: string;
  let gitUrl: string;
  let auth: any;

  robot.router.post(urlpath, (req: any, res: any) => {
    const auth  = new Auth(req, allow, deny, apikey);

    if (!auth.checkRequest(res)) {
      console.log(`not allowed: ${auth.remoteIp}`);
      return;
    }

    if (!req.body) {
      throw new Error(`${name}> no body: ${JSON.stringify(req)}`);
    }

    log.debug(`data: ${JSON.stringify(req.body)}`);
    const query: string = querystring.parse(url.parse(req.url).query);
    res.end('OK');

    const body: any = req.body;
    let payload;

    if (body.payload) {
      payload = body.payload;
    } else {
      payload = body;
    }

    if (!payload.repository) {
      throw new Error(`${name}> no repository: ${JSON.stringify(payload)}`);
    }

    log.debug(`payload.repository: ${JSON.stringify(payload.repository)}`);

    // gitlab
    if (payload.repository.homepage) {
      gitUrl = payload.repository.homepage;
      service = 'gitlab';
    }

    // github
    if (payload.repository.url) {
      log.debug(`payload.repository: ${JSON.stringify(payload.repository)}`);
      log.debug(`github pattern 1.`);
      gitUrl = payload.repository.url;
      service = 'github';
    }
    if (payload.repository.html_url) {
      log.debug(`github pattern 2.`);
      gitUrl = payload.repository.html_url;
      service = 'github';
    }

    if (!gitUrl) {
      throw new Error(`${name}> Unknown git repository.`);
    }

    log.debug(`${name}> git url: ${gitUrl}`);

//    if (!(body.ref || payload.ref)) {
//      return;
//    }

    let branch: string = '';
    if (service == 'github') {
      if (!payload.ref){
        throw new Error(`${name}> github: no ref: ${payload.ref} `);
      }

      branch = payload.ref.replace(/refs\/heads\//, '');
    }

    const gitInfo: any = conf[gitUrl];
    let authInfo: typeAuthInfo;

    if (gitInfo['auth']) {
      authInfo = {
        user: gitInfo['auth']['id'],
        pass: gitInfo['auth']['password']
      };
    // } else {
    //   log.debug(`${name}> No auth infomation.`);
    }

    // const jobUrl: string | Array<string> = gitInfo['jobs'][branch];
    const jobUrl: any = gitInfo['jobs'][branch];
    const jobRequest: any = (url: string) => {

      if (authInfo) {
        request
          .post(url)
          .auth(authInfo.user, authInfo.pass)
          .end((err:string, res: any) => {
            if (err) {
              log.error(`${name}> request error: ${err}`);
              return;
            }
          });
      } else {
        request
          .post(url)
          .end((err: string, res: any) => {
            if (err) {
              log.error(`${name}> request error: ${err}`);
              return;
            }
          });
      }

      const info: typeMessageInfo = { color: color };

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
      log.debug(`${name}> no jobUrl for ${branch}`);
    }

  });
};
