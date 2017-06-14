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

/* @flow */
import fs            from 'fs';
import yaml          from 'js-yaml';
import child_process from 'child_process';

import SendMessage   from './SendMessage';
import Auth          from './Auth';

const prefix      = '[cmd]';
const debug       = process.env.CMD_DEBUG;
const configFile  = process.env.CMD_CONFIG;
const type        = process.env.HUBOT_IRC_TYPE;
const name        = 'cmd';
const USER        = 'user';
const MESSAGE     = 'message';
const COMMAND     = 'command';

module.exports = (robot) => {
  const sm  = new SendMessage(robot, type);
  const log = sm.robot;

  if (!configFile) {
    log.error(`${name}> no config file.`);
    return;
  }

  const conf = yaml.safeLoad(fs.readFileSync(configFile));

  const execCommand = (msg, cmd, arg) => {
    const room    = `#${msg.message.user.room}`;
    const target  = [ room ];
    const exec    = child_process.exec;
    const message = {};
    const result  = [];
    const command = arg ? `${cmd} ${arg}` : cmd;

    exec(command, (err, stdout, stderr) => {
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

  const checkPrivilege = (list, user) => {
    let flag = false;

    list.map((l) => {
      if (l == user) {
        flag = true;
      }
    });

    return flag === true ? true : false;
  };

  const help = (msg, title, message) => {
    const room     = `#${msg.message.user.room}`;
    const target   = [ room ];
    const messages = [message];

    if (!title) {
      title = 'Usage: cmd TARGET ACTION (ARGUMENT).';
    }

    messages.push("Here is my task list.\n\n");
    Object.keys(conf).map((target) => {
      Object.keys(conf[target]).map((action) => {
        messages.push(`*${target} ${action}*: \n  ${conf[target][action][MESSAGE]}\n\n  [command]\n    \`${conf[target][action][COMMAND]}\`\n\n  [user]\n    ${conf[target][action][USER].join(', ')}`);
      });
    });

    msg.send(`[${title}]\n\n${messages.join("\n\n")}`);
  };

  robot.hear(/cmd help/i, (msg) => {
    help(msg);
  });

  robot.hear(/cmd (\w+) (\w+) ?(\w+)?/i, (msg) => {
    const target  = msg.match[1];
    const action  = msg.match[2];
    const arg     = msg.match[3];
    const title   = `*${target} ${action}*`;
    let flag      = false;

    Object.keys(conf).map((t) => {
      const actions = conf[target];
      if (target == t) {
        Object.keys(actions).map((a) => {
          const act = actions[a];

          if (action != a) {
            return;
          }
          
          flag = true;

          if (!checkPrivilege(act[USER], msg.message.user.name)) {
            console.log(`Not allowed user: ${msg.message.user.name}`);
            msg.send(`Not allowed user: ${msg.message.user.name}.\n\nPlease contact the administrator.`);
            return;
          }
          const cmd = arg ? `${act[COMMAND]} ${arg}` : `${act[COMMAND]}`;
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
