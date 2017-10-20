/* @flow */

/**
 * HUBOT_IRC_INFO: path to the yaml file of configuration.
 *
 * yaml format
 *
 * ----
 * webhook_url:
 *   #foo: 'https://hooks.slack.com/services/XXXXX/YYYYY'
 *   #bar: 'https://hooks.slack.com/services/YYYYY/ZZZZZ'
 *
 */

import fs      from 'fs';
import yaml    from 'js-yaml';
import path    from 'path';
import request from 'superagent';
import Context from './Context';

export default class Slack extends Context {

  robot:            any;
  color:            string;
  info:             any;
  buildAttatchment: (msg: string, info: any) => any;
  send:             (target: string, msg: string, info: any, cb: () => any) => any;

  /**
   * Constructor
   * @param  {Object} robot hubot object.
   *
   * @throws {Error}  arguments error.
   */
  constructor(robot: any): void {
    if (!robot) {
      throw new Error(`arguments error: robot is not found.`);
    }

    const conf: string = process.env.HUBOT_IRC_INFO || '';
    if (!conf) {
      console.log(`Slack: there is no info setting. please set HUBOT_IRC_INFO.`);
      return;
    }

    super();
    this.robot            = robot;
    this.color            = '#aaaaaa';
    this.info             = yaml.safeLoad(fs.readFileSync(conf));

    this.buildAttatchment = this.buildAttatchment.bind(this);
    this.send             = this.send.bind(this);
  }

  /**
   * Print bold text.
   * @param  {String} str text.
   * @return {Sring}  bold text for irc.
   */
  bold(str: string): string {
    return str ? ` *${str}* ` : '';
  }

  /**
   * Print url text.
   * @param  {String} title title of url.
   * @param  {String} url   url.
   * @return {String} url text for irc.
   */
  url(title: string, url: string): string {
    if (!(title && url)) {
      return '';
    } else {
      return `<${url}|${title}>`;
    }
  }

  /**
   * Print underline text.
   * @param  {String} str text.
   * @return {Sring}  bold text for irc.
   */
  underline(str: string): string {
    return str ? ` *${str}* ` : '';
  }

  /**
   * Build attachment for slack.
   * @param  {String} msg  the message.
   * @param  {Object} info the infomation for building attachment.
   * @return {String} attachment for slack.
   */
  buildAttatchment(msg: string, info: any={}): any {
    if (!msg) {
      return null;
    }

    const fallback: Array<string> = [
      'pretext',
      'title',
      'title_link'
    ];
    const querys: Array<string> = [
      'pretext',
      'title',
      'title_link',
      'author_name',
      'author_link',
      'author_icon',
      'image_url',
      'thumb_url',
      'fields',
      'color'
    ];

    const at: any          = {};
    const message: string  = this.parseType(msg);

    at.color = info.color ? info.color : this.color;
    at.text  = message;

    const hash: mixed = fallback.reduce((hash, key) => {
      if (info[key]) {
        hash[key] = info[key];
      }
      return hash;
    }, {});

    const f: Array<string> = fallback.reduce((array, a) => {
      if (info[a]) {
        array.push(info[a]);
      }
      return array;
    }, []);
    f.push(message);
    at.fallback = f.join(' - ');

    at.mrkdwn_in = ['text', 'pretext'];

    querys.map((v, i) => {
      if (info[v]) {
        at[v] = info[v];
      }
    });

    if (this.debugFlag) {
      this.debug(`Slack: attachment: ${JSON.stringify(at)}`);
    }

    return [at];
  }

  /**
   * Send message to hubot.
   * @param  {String} target  chat room.
   * @param  {String} msg     the message.
   * @param  {Object} info    the infomation for message.
   * @return {Promise} Promis object.
   *
   * @throws {Error}  arguments error.
   */
  send(target: string, msg: string, info: any={}, cb: (str: ?string, obj: ?any) => any) {
    const name: string = "Slack send";

    if (!(target && msg)) {
      throw new Error(`Irc send: arguments error: target: ${target}, msg: ${msg}`);
    }

    if (!this.info.webhook_url[target]) {
      this.error(`${name}> No webhook url for target: ${target}.`);
      return;
    }

    const q: any                = {};
    const params: Array<string> = [
      'color',
      'username',
      'as_user',
      'parse',
      'link_name',
      'unfurl_links',
      'unfurl_media',
      'icon_url',
      'icon_emoji'
    ];

    q.channel     = target;
    q.attachments = this.buildAttatchment(msg, info);

    this.debug(`${name}> json: ${JSON.stringify(q)}`);
    this.debug(`urls: ${JSON.stringify(this.info.webhook_url)}`);
    this.debug(`target: ${target}`);
    this.debug(`webhook: ${this.info.webhook_url[target]}`);

    request
      .post(this.info.webhook_url[target])
      .send(q)
      .end((err, res) => {
        if (err || !res.ok) {
          cb && cb(err);
          return;
        }

        this.debugFlag && this.debug(`${name}> body from slack; ${res.text}`);
        cb && cb(null, res.text);
      });
//    this.robot.send(target, q);
  }
}
