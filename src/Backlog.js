/* @flow */
import SendMessage from './SendMessage';
import Auth        from './Auth';

const type: string       = process.env.HUBOT_IRC_TYPE || 'slack';
const backlogUrl: string = process.env.BACKLOG_URL || '';
const urlpath: string    = '/hubot/backlog/:room';
const name: string       = 'Backlog';

module.exports = (robot: any): void => {

  if (!backlogUrl) {
    return;
  }

  robot.router.post(urlpath, (req: any, res: any) => {
    const body: any    = req.body;
    const room: string = req.params.room;
    const sm           = new SendMessage(robot, type);
    let label: string  = '';
    let url: string;
    let message: string;

    console.log(`body: ${JSON.stringify(req.body)}`);
    try {
      switch (body.type) {
      case 1:
        label = '課題の追加';
        break;

      case 2, 3:
        label = '課題の更新';
        break;

      case 5:
        label = 'wikiの追加';
        break;

      case 6:
        label = 'wikiの更新';
        break;

      case 8:
        label = 'ファイルの追加';
        break;

      case 9:
        label = 'ファイルの更新';
        break;

      default:
        break;
    }

      url = `${backlogUrl}/view/${body.project.projectKey}-${body.content.key_id}`;
      if (body.content && body.content.comment && body.content.comment.id) {
        url += `#comment-${body.content.comment.id}`;
      }

      message = `*Backlog ${label}*
`;
      message += `[${body.project.projectKey}-${body.content.key_id}] - `;
      message += `${body.content.summary} _by ${body.createdUser.name}_
>>> `;
      if (body.content && body.content.comment) {
        message += `${body.content.comment.content}
`;
      }

      message += `${url}`;

      if (!message) {
        //        robot.messageRoom(room, 'Backlog integration error.');
        sm.send(room, 'Backlog integration error.');
        res.end('Error');
      }

      //      robot.messageRoom(room, message);
      sm.send(room, message, {});
      res.end('OK');

    } catch (e) {
      console.dir(e);
    }

  });
};
