import Context from './Context';

export default class Irc extends Context {
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
    this.robot      = robot;
    this.msgLabel   = 'text';
    this.lineFeed   = "\n";

    this.htmlFilter = this.htmlFilter.bind(this);
    this.send       = this.send.bind(this);
  }

  /**
   * Print bold text.
   * @param  {String} str text.
   * @return {Sring}  bold text for irc.
   */
  bold(str) {
    return str ? "\x02" + str + "\x02" : null;
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
      return "\x1f" + title + "\x1f" + ": " + url;
    }
  }

  /**
   * Replace html to text.
   * @param  {String} html html.
   * @return {String} text.
   */
  htmlFilter(html) {
    if (!html) {
      return null;
    } else {
      return html.replace(/<br>/g, this.lineFeed)
        .replace(/<br \/>/g, this.lineFeed)
        .replace(/<("[^"]*"|'[^']*'|[^'">])*>/g, '')
        .replace(/^$/g, '')
        .replace(/^${this.lineFeed}$/g, '');
    }
  }

  /**
   * Send message to hubot.
   * @param  {String} target chat room.
   * @param  {String} msg    the message.
   *
   * @throws {Error}  arguments error.
   */
  send(target, msg) {
    if (!(target && msg)) {
      throw new Error(`Irc send: arguments error: target: ${target}, msg: ${msg}`);
      this.robot.send({ 'room': target}, this.parseType(msg));
    }
  }
}
