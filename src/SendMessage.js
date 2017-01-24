import fs      from 'fs';
import request from 'superagent';
import Irc     from './Irc';
import Slack   from './Slack';

/**
 * send
 */
export default class SendMessage {
  constructor(robot, type) {
    if (!(robot && type)) {
      throw new Error(`${this.name} arguments error: robot: ${robot}, type: ${type}`);
    }

    this.name = 'SendMessage';

    switch (type) {
    case "irc":
      this.robot = new Irc(robot);
      break;
    case "slack":
      this.robot = new Slack(robot);
      break;
    default:
      throw new Error(`${this.name}: unknown type: ${type}`);
    }
  }

  send(target, msg, option={}) {
    if (!(target && msg)) {
      throw new Error(`${this.name}> arguments error: target: ${target}, msg: ${msg}`);
    }

    let targets;
    if (this.robot.checkType('String', target)) {
      targets = [target];
    } else {
      targets = target;
    }

    targets.map((v, i) => this.robot.send(v, msg, option));
  }
}
