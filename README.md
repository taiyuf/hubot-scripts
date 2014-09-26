hubot-scripts
=============

hubot scripts.

# Configuration

## Dependencies

  hubot-irc: "~0.2.2"

## Usage

Here is sample configuration. See https://github.com/nandub/hubot-irc.

### IRC

```
# basic
export HUBOT_HOME=/home/hubot
export NODE_PATH=${HUBOT_HOME}/node_modules
export REDIS_URL="redis://127.0.0.1:6379"
export PORT=19999

# IRC
export HUBOT_IRC_TYPE="irc"
export HUBOT_IRC_ROOMS="#dummy"
export HUBOT_IRC_SERVER="hoge"
export HUBOT_IRC_USERNAME="hubot"
export HUBOT_IRC_PASSWORD="******"
export HUBOT_IRC_PORT="6667"

${HUBOT_HOME}/bin/hubot -a irc
```

### HTTP_POST

```
# basic
export HUBOT_HOME=/home/hubot
export NODE_PATH=${HUBOT_HOME}/node_modules
export REDIS_URL="redis://127.0.0.1:6379"
export PORT=19999

# http_post
export HUBOT_IRC_TYPE="http_post"
export HUBOT_IRC_ROOMS="#dummy" # dummy text
export HUBOT_IRC_SERVER="hoge"  # dummy text
export HUBOT_IRC_INFO=${HUBOT_HOME}/headers.json # custom headers as json
export HUBOT_IRC_MSG_TYPE="string"
export HUBOT_IRC_MSG_LABEL="message"
export HUBOT_IRC_FMT_LABEL="format"

${HUBOT_HOME}/bin/hubot -a irc
```

HUBOT_IRC_INFO:

```
{
    "ITEM_LABEL": "ITEM_VALUE"
}
```

### idobata

```
# basic
export HUBOT_HOME=/home/hubot
export NODE_PATH=${HUBOT_HOME}/node_modules
export REDIS_URL="redis://127.0.0.1:6379"
export PORT=19999

# idobata
export HUBOT_IRC_TYPE="idobata"
export HUBOT_IRC_ROOMS="#dummy" # dummy text
export HUBOT_IRC_SERVER="hoge"  # dummy text
export HUBOT_IRC_INFO=${HUBOT_HOME}/headers.json # custom headers as json

${HUBOT_HOME}/bin/hubot -a irc
```

HUBOT_IRC_INFO:

```
{
    "header": {"X-API-Token": "YOUR_API_TOKEN"}
}
```

### chatwork

```
# basic
export HUBOT_HOME=/home/hubot
export NODE_PATH=${HUBOT_HOME}/node_modules
export REDIS_URL="redis://127.0.0.1:6379"
export PORT=19999

# chatwork
export HUBOT_IRC_TYPE="chatwork"
export HUBOT_IRC_ROOMS="#dummy" # dummy text
export HUBOT_IRC_SERVER="hoge"  # dummy text
export HUBOT_IRC_INFO=${HUBOT_HOME}/headers.json # custom headers as json

${HUBOT_HOME}/bin/hubot -a irc
```

HUBOT_IRC_INFO:

```
{
    "header": {"X-ChatWorkToken": "YOUR_TOKEN"}
}
```

### slack

```
# basic
export HUBOT_HOME=/home/hubot
export NODE_PATH=${HUBOT_HOME}/node_modules
export REDIS_URL="redis://127.0.0.1:6379"
export PORT=19999

# slack
export HUBOT_IRC_TYPE="slack"
export HUBOT_IRC_ROOMS="#dummy" # dummy text
export HUBOT_IRC_SERVER="hoge"  # dummy text
export HUBOT_IRC_INFO=${HUBOT_HOME}/slack_info.json # custom infomation as json

${HUBOT_HOME}/bin/hubot -a irc
```

If you use hubot-slack, Please activate Hubot API.

```
# basic
export HUBOT_HOME=/home/hubot
export NODE_PATH=${HUBOT_HOME}/node_modules
export REDIS_URL="redis://127.0.0.1:6379"
export PORT=19999

# slack
export HUBOT_IRC_SERVER="hoge"  # dummy text
export HUBOT_IRC_INFO=${HUBOT_HOME}/slack_info.json # custom infomation as json
export HUBOT_SLACK_TOKEN=******************
export HUBOT_SLACK_TEAM=YOUR_TEAM
export HUBOT_SLACK_BOTNAME=slackbot

${HUBOT_HOME}/bin/hubot -a slack
```

HUBOT_IRC_INFO:

```
{
    "team_url": "hoge.slack.com",      # required
    "token: {"#channel1": "hogehoge",  # required
             "#channel2": "fugafuga"},
    "username": "hubot",               # optional. default is "hubot"
    "icon_emoji": ":ghost:"            # optional
}
```

token is Slack API IncommingWebhook's token.

### HipChat

```
# basic
export HUBOT_HOME=/home/hubot
export NODE_PATH=$HUBOT_HOME/node_modules
export REDIS_URL="redis://127.0.0.1:6379"
export PORT=19998

# hipchat
export HUBOT_IRC_ROOMS="#dummy"
export HUBOT_IRC_SERVER="hoge"
export HUBOT_IRC_TYPE="hipchat"
export HUBOT_IRC_INFO="$HUBOT_HOME/hipchat_info.json"

${HUBOT_HOME}/bin/hubot -a irc
```

HUBOT_IRC_INFO:

```
{
        "target": {"ROOM1_NAME": {"id": ROOM1_ID,
                                  "token": "ROOM1_TOKEN",
                                  "color": "blue"},
                   "ROOM2_NAME": {"id": ROOM2_ID,
                                  "token": "ROOM2_TOKEN",
                                  "color": "green"},
                  },
        "color": "blue"  # default back ground color
}
```

* ROOM_ID:    Group Admin -> Rooms -> API ID
* ROOM_TOKEN: Group Admin -> Rooms -> Room Notification Tokens
* "color" is allowed in "yellow", "red", "green", "purple", "gray", or "random".

# Modules

## http_irc

Simple path to have Hubot echo out anything in the message querystring for a given room.

if you want to tell the room '#test' on IRC server, room is '%23test'.

### GET

GET http://YOUR_SERVER/http_irc?message=hoge&room=%23test

ex)

```
curl http://YOUR_SERVER/http_irc?message=hoge&room=%23test
```

### POST

POST /http_irc?room=%23<room> or POST /http_irc

```
curl -X POST --data-urlencode message="hoge hoge." http://YOUR_SERVER/http_irc?room\=%23test

curl -X POST --data-urlencode message="hoge hoge." -d  room=%23foo http://YOUR_SERVER/http_irc
```

## read_rss

Simple RSS Reader for irc and group chat system.

### Configuration

* RSS_CONFIG_FILE: path to configuration file(json format).
* RSS_LABEL:       if you create many bots, you define a unique keyword.

You need to write configuration file as json format.

```
{
  "keyword1": {"feed": {"url": "http://...."},
               "target": ["#hoge", "#fuga"]},    # IRC
  "keyword2": {"feed": {"url": "http://...",
                        "id": "user",
                        "password": "password"},
               "target": ["http://....", "http://...."]}      # Other
}
```

url, room(idobata channel's url) fields are required. if the site require the basic
authentication, you need to set id, password fields.

## gitlab

Post gitlab related events using gitlab hooks

### Configuration

* GITLAB_URL: gitlab web site url. if your gitlab module's url is http://hoge.com/USER/MODULE.git, the GITLAB_URL value is http://hoge.com.
* GITLAB_CONFIG_FILE: the path to configuration file.

configuration file like below,

IRC

```
{
    "DEFAULT": {"target": ["#hoge"]},
    "http://YOUR_GIT_WEB_SITE/USER/HOGE": {"target": ["#hoge", "#fuga"]},
    "http://YOUR_GIT_WEB_SITE/USER/FUGA": {"target": ["#fuga"]},
    ...,
}
```

Other

```
{
    "DEFAULT": {"target": ["http://...."]},
    "http://YOUR_GIT_WEB_SITE/USER/HOGE": {"target": ["http://....", "http://...."]},
    "http://YOUR_GIT_WEB_SITE/USER/FUGA": {"target": ["http://...."]},
    ...,
}
```

DEFAULT: "DEFAULT" is string. hubot tell the message to this room which is not specified.


### Usage

Put http://<HUBOT_URL>:<PORT>/gitlab/system as your system hook

Put http://<HUBOT_URL>:<PORT>/gitlab/web as your web hook (per repository)

## jenkins-notify

Notifies about Jenkins build errors via Jenkins Notification Plugin.

https://wiki.jenkins-ci.org/display/JENKINS/Notification+Plugin

### Configuration

* JENKINS_NOTIFY_CONFIG_FILE: concfigration file path.
* JENKINS_NOTIFY_BACK_TO_NORMAL: if this value set true, send message when the job status change (FAILURE -> SUCCESS or SUCCESS -> FAILURE).

configuration file like this,

IRC

```
{
     "GIT_REPOSITORY": {"target": ["#hoge"],
                        ...,
                       }
}
```

Other

```
{
     "GIT_REPOSITORY": {"target": ["http://....."],
                        ...,
                       }
}
```

hubot send the message like this.

```
[Jenkins]
build #60 has completed in SUCCESS. (details)
elapsed time: 00:00:53

project: Your Project
repository: ssh://gitlab@gitlab.YOURSITE/SOMEONE/PROJECT_NAME
branch: origin/BRANCH
commit: 6ff2e02f57d3d43fd49443b2b5f7e26bada64c0d
```


* GIT_REPOSITORY: ex. ssh://GITLABUSER@GITLAB_URL/USER/PROJECT.git

* TARGET: channel name for IRC, or end point url for other group chat services.


### Usage

Put http://<HUBOT_URL>:<PORT>/hubot/jenkins-notify to your Jenkins

* Job Notifications -> Notification Endpoints

```
Format: JSON
Protocol: HTTP
Event: All Event
URL: http://<HUBOT_URL>:<PORT>/hubot/jenkins-notify
Timeout: as you like
```

## jenkins-job-selector-by-git-branch

Do the job selected by the branch of git on jenkins

### Configuration

* JENKINS_JOBSELECTOR_CONFIG_FILE concfigration file path.

configuration file like this,

```
{
   "GIT_URL": {
                  "target": ["hoge", "fuga"],
                  "auth": {"id": "hoge",
                           "password": "fuga"},
                  "jobs":{"branchA": "JENKIS_JOB_URL_A",
                          "branchB": "JENKIS_JOB_URL_A"}
                 }
}
```

if you have an api key, JENKINS_JOB_URL is like this.

```
http://USER:USER_API_KEY@JENKINS_SERVER_URL/.../job/PROJECT_NAME/build?token=USER_API_KEY
```

### Usage

Put http://<HUBOT_URL>:<PORT>/hubot/jenkins-jobselector to web hook at your git repository.


## cmd

Let hubot execute shell command.

### Configuration

* CMD_CONFIG: path to configuration file

You need write CMD_CONFIG file in json format like this.

```
{
    "TARGET1": {"ACTION1": {"command": "/path/to/cmd1 ACTION1",
                            "user": ["foo", "bar"],
                            "message": "/path/to/cmd1 ACTION1 is executed."}
                "ACTION2": {"command": "/path/to/cmd1 ACTION2",
                            "user": ["foo"],
                            "message": "/path/to/cmd1 ACTION2 is executed."}},
    "TARGET2": {"ACTION1": {"command": "/path/to/cmd2 ACTION1",
                            "user": ["foo", "bar"],
                            "message": "/path/to/cmd2 ACTION1 is executed."}}
}
```

You need to execute hubot as adapter for each group chat system, too.
If you use slack, you need to hubot-slack adapter.

You need to let hubot user allow to execute command on your system (ex. sudo).

Each ACTION has these properties:

* command: the expression to execute command.
* user:    the list of user allowed to execute the command.
* message: the message to let hubot tell when the command executed.

### Usage

Tell bot to order.

```
@bot cmd TARGET ACTION
```
