/**
 * Description
 * Let hubot execute shell command.
 *
 * Dependencies:
 * send_message: include this module
 *
 * Configuration:
 * CMD_CONFIG: path to configuration file
 * CMD_MSG_COLOR: color
 *
 * hipchat "color" is allowed in "yellow", "red", "green", "purple", "gray", or "random".
 *
 * You need write CMD_CONFIG file in json format like this.
 *
 * {
 *   "TARGET1": {
 *     "ACTION1": {
 *       "command": "/path/to/cmd1 ACTION1",
 *       "user": ["foo", "bar"],
 *       "message": "/path/to/cmd1 ACTION1 is executed."
 *     },
 *     "ACTION2": {
 *       "command": "/path/to/cmd1 ACTION2",
 *       "user": ["foo"],
 *       "message": "/path/to/cmd1 ACTION2 is executed."
 *     }
 *   },
 *   "TARGET2": {
 *     "ACTION1": {
 *       "command": "/path/to/cmd2 ACTION1",
 *       "user": ["foo", "bar"],
 *       "message": "/path/to/cmd2 ACTION1 is executed."
 *     }
 *   }
 * }
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
 * @bot cmd TARGET ACTION
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
const color       = process.env.CMD_MSG_COLOR || '#aaaaaa';
const type        = process.env.HUBOT_IRC_TYPE;
const name        = 'cmd';

module.exports = (robot) => {
  const sm      = new SendMessage(robot, type);
  const log     = sm.robot;
  const options = {
    color: color
  };

  if (!configFile) {
    log.error(`${name}> no config file.`);
    return;
  }

  const conf = yaml.safeLoad(fs.readFileSync(configFile));

  const tell = (msg, title, message) => {
    const room    = `#${msg.message.user.room}`;
    const target  = [ room ];
    options.title = title;

    sm.send(target, message, options);
  };

  const execCommand = (msg, cmd) => {
    const room    = `#${msg.message.user.room}`;
    const target  = [ room ];
    const exec    = child_process.exec;
    const message = {};
    const result  = [];

    exec(cmd, (err, stdout, stderr) => {
      if (err || stderr) {
        tell(msg, '[Unknown error]', `#{err}\n#{stderr}`);
        return;
      }

      if (!stdout) {
        tell(msg, '[Result]', 'executed in success.');
        return;
      }

      tell(msg, '[Result]', stdout);
    });
  };

  const checkPrivilege = (list, user) => {
    let flag = false;

    list.map((l) => {
      if (l == user) {
        flag = true;
      }
    });

    if (flag == false) {
      return false;
    }

    return true;
  };

  const help = (msg, title, message) => {
    const room     = `#${msg.message.user.room}`;
    const target   = [ room ];
    const messages = [message];

    if (!title) {
      title = 'Usage: cmd TARGET ACTION.';
    }

    messages.push("Your order is not match my task list. Please check again.\n");
    Object.keys(conf).map((key) => {
      Object.keys(conf[key]).map((key2) => {
        messages.push(`- ${key} ${key2}: ${conf[key]['command']}\n${conf[key][key2]['message']}.\n  by ${conf[key][key2]['user'].join(', ')}`);
      });
    });

    tell(msg, title, messages.join("\n"));
  };

  robot.respond(/cmd (\w+) (\w+)/i, (msg) => {
    const title = `${prefix} ${msg.match[1]} ${msg.match[2]}`;

    Object.keys(conf).map((key) => {
      const value = conf[key];
      switch (msg.match[1]) {
      case key:
        Object.keys(value).map((key2) => {
          const value2 = value[key2];

          if (!checkPrivilege(value2['user']), msg.message.user.name) {
            console.log(`action not found: ${msg.match[2]}`);
            tell(msg, 'Action not found.', `action not found: ${msg.match[2]}.\n\nSee HUBOT_NAME cmd help.`);
            return;
          }

          tell(msg, title, value2['message']);
          execCommand(msg, value2['command']);
          return;
        });
        break;
        
      default:
        console.log(`target not found: ${msg.match[1]}`);
        tell(msg, 'Target not found', `target not found: ${msg.match[1]}.\n\nSee HUBOT_NAME cmd help.`);
        return;
      }
    });    
  });

  robot.respond(/cmd help/i, (msg) => {
    help(msg);
  });
};
