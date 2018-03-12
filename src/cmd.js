/* @flow */

/**
 * Description
 * Let hubot execute shell command.
 *
 * Dependencies:
 * send_message: include this module
 *
 * Configuration:
 * CMD_CONFIG: path to configuration file
 *
 * You need write CMD_CONFIG file in yaml format like this.
 *
 * TARGET1:
 *   ACTION1:
 *     command: "/path/to/cmd1 ACTION1"
 *     user:
 *       - "foo"
 *       - "bar"
 *     message: "/path/to/cmd1 ACTION1 is executed."
 *   ACTION2:
 *     command: "/path/to/cmd1 ACTION2"
 *     user:
 *       - "foo"
 *       - "bar"
 *     message: "/path/to/cmd1 ACTION2 is executed."
 * TARGET2:
 *   ACTION1:
 *     command: "/path/to/cmd2 ACTION1"
 *     user:
 *       - "foo"
 *       - "bar"
 *     message: "/path/to/cmd2 ACTION1 is executed."
 *
 * You need to execute hubot as adapter for each group chat system.
 * If you use slack, you need to hubot-slack adapter.
 *
 * You need to let hubot user allow to execute command on your system (ex. sudo).
 * Each ACTION has these properties:
 * command: the expression to execute command.
 * user:    the list of user allowed to execute the command.
 * message: the message to let hubot tell when the command executed.
 *
 * Commands:
 * Tell bot to order.
 * @hubot cmd TARGET ACTION ARG
 *
 * Author:
 * Taiyu Fujii
 */

import fs            from 'fs';
import yaml          from 'js-yaml';
import child_process from 'child_process';

import SendMessage   from './SendMessage';
import Auth          from './Auth';

const prefix: string      = '[cmd]';
const debug: string       = process.env.CMD_DEBUG || 'false';
const configFile: string  = process.env.CMD_CONFIG || '';
const type: string        = process.env.HUBOT_IRC_TYPE || 'slack';
const name: string        = 'cmd';
const USER: string        = 'user';
const MESSAGE: string     = 'message';
const COMMAND: string     = 'command';

module.exports = (robot: any) => {
  const sm: any  = new SendMessage(robot, type);
  const log: any = sm.robot;

  if (!configFile) {
    log.error(`${name}> no config file.`);
    return;
  }

  const conf: any = yaml.safeLoad(fs.readFileSync(configFile));

  const execCommand = (msg, cmd, arg): void => {
    const room: string           = `#${msg.message.user.room}`;
    const target: Array<string>  = [ room ];
    const exec: any              = child_process.exec;
    const command: string        = arg ? `${cmd} ${arg}` : cmd;

    exec(command, (err: string, stdout: string, stderr: string) => {
      if (err) {
        msg.send(`[Unknown error]\n\n${err}\n${stderr}`);
        return;
      }

      if (!stdout) {
        msg.send(`[Result]\n  executed in success.`);
        return;
      }
      msg.send(`[Result]\n  \`${stdout}\``);
    });
  };

  const checkPrivilege = (list: Array<string>, user: string): boolean => {
    let flag = false;

    list.map((l) => {
      if (l == user) {
        flag = true;
      }
    });

    return flag === true ? true : false;
  };

  const help = (msg: any): void => {
    const room     = msg.message.user.room;
    const target   = [ room ];
    const messages = ['*USAGE: cmd TARGET ACTION (ARGUMENT)*', 'Here is my task list.'];

    Object.keys(conf).map(target => {
      Object.keys(conf[target]).map(action => {
        const cmds = `\*${target} ${action}\*:
  ${conf[target][action][MESSAGE]}

  [command]
    \`${conf[target][action][COMMAND]}\`

  [user]
    ${conf[target][action][USER].join(', ')}`;

        messages.push(cmds);
      });
    });

    msg.send(messages.join("\n\n"));
  };

  robot.respond(/cmd help/i, (msg: any) => {
    help(msg);
  });

  robot.respond(/cmd (\w+) (\w+) ?([A-Za-z0-9_\.]+)?/i, (msg: any) => {
    const target  = msg.match[1];
    const action  = msg.match[2];
    const arg     = msg.match[3];
    const title   = `*${target} ${action}*`;
    let flag      = false;

    Object.keys(conf).map((t) => {
      const actions: any = conf[target];
      if (target == t) {
        Object.keys(actions).map((a) => {
          const act: any = actions[a];

          if (action != a) {
            return;
          }

          flag = true;

          if (!checkPrivilege(act[USER], msg.message.user.name)) {
            console.log(`Not allowed user: ${msg.message.user.name}`);
            msg.send(`Not allowed user: ${msg.message.user.name}.\n\nPlease contact the administrator.`);
            return;
          }
console.log(`arg: ${arg}`);
          const cmd: string = arg ? `${act[COMMAND]} ${arg}` : `${act[COMMAND]}`;
          msg.send(`${title}\n  ${act[MESSAGE]}\n\n[command]\n  \`${cmd}\`\n\n`);
          execCommand(msg, act[COMMAND], arg);
        });
      }
    });

    if (flag === false) {
      console.log(`target not found: ${target}`);
      msg.send(`Target not found: ${target}.\n\nTry @HUBOT_NAME cmd help.`);
    }
  });
};
