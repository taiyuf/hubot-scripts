import path      from 'path';
import request   from 'superagent';
import Context   from './Context';

export default class Slack extends Context {

  /**
   * Constructor
   * @param  {Object} robot hubot object.
   *
   * @throws {Error}  arguments error.
   */
  constructor(robot) {
    if (!robot) {
      throw new Error(`arguments error: robot is not found.`);
    }

    super();
    this.robot       = robot;
    this.formatLabel = 'payload';
    this.color       = '#aaaaaa';
    this.info        = process.env.HUBOT_IRC_INFO;

    this.buildAttatchment = this.buildAttatchment.bind(this);
    this.send = this.send.bind(this);
  }

  /**
   * Print bold text.
   * @param  {String} str text.
   * @return {Sring}  bold text for irc.
   */
  bold(str) {
    return str ? " *#{str}* " : null;
  }

  /**
   * Print url text.
   * @param  {String} title title of url.
   * @param  {String} url   url.
   * @return {String} url text for irc.
   */
  url(title, url) {
    if (!(title && url)) {
      return null;
    } else {
      return `<${url}|${title}>`;
    }
  }

  /**
   * Print underline text.
   * @param  {String} str text.
   * @return {Sring}  bold text for irc.
   */
  underline(str) {
    return str ? " *#{str}* " : null;
  }

  /**
   * Build attachment for slack.
   * @param  {String} msg  the message.
   * @param  {Object} info the infomation for building attachment.
   * @return {String} attachment for slack.
   */
  buildAttatchment(msg, info={}) {
    if (!msg) {
      return null;
    }

    const fallback = [
      'pretext',
      'title',
      'title_link'
    ];
    const querys = [
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

    const at       = {};
    const message  = this.parseType(msg);

    at.color = info.color ? info.color : this.color;
    at.text  = message;

    fallback.map((v, i) => {
      if (info[v]) {
        fallback.push(v);
      }
    });

    fallback.push(message);
    at.fallback = fallback.join(' - ');

    at.mrkdwn_in = ['text', 'pretext'];

    querys.map((v, i) => {
      at[v] = info[v];
    });

    if (this.debugFlag) {
      this.debug(`Slack: attachment: ${JSON.stringify(at)}`);
    }

    return at;
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
  send(target, msg, info={}) {
    if (!(target && msg)) {
      throw new Error(`Irc send: arguments error: target: ${target}, msg: ${msg}`);
      this.robot.send({ 'room': target}, this.parseType(msg));
    }

    const name   = "Slack send";
    const q      = {};
    const params = [
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

    q.channel = target;
    q.attachments = this.buildAttatchment(msg, info);

    params.map((v, i) => {
      if (info[v]) {
        q[v] = info[v];
      }
    });

    this.debugFlag && this.debug(`${name}> json: ${JSON.stringify(q)}`);

    return new Promise((resolve, reject) => {
      request
        .post(this.info.webhook_url)
        .send(q)
        .end((err, res) => {
          if (err || !res.ok) {
            reject(err);
            return;
          }

          this.debugFlag && this.debug(`${name}> body from slack; ${res.text}`);
          resolve(res.text);
        });
    });
  }
}
