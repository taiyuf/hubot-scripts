hubot-scripts
=============

hubot scripts.

# Configuration

## Dependencies

- hubot-irc: "~0.2.2"
- fs
- js-yaml
- log4js
- querystring
- request
- url

## Usage

Here is sample configuration. See https://github.com/nandub/hubot-irc.

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
export HUBOT_IRC_INFO=${HUBOT_HOME}/slack_info.yml # custom infomation as yaml.
export HUBOT_SLACK_TOKEN=******************
export HUBOT_SLACK_TEAM=YOUR_TEAM
export HUBOT_SLACK_BOTNAME=slackbot

${HUBOT_HOME}/bin/hubot -a slack
```

HUBOT_IRC_INFO:

```
webhook_url: "https://hooks.slack.com/services/....."
```

token is Slack API IncommingWebhook's token.

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

### for slack

There are some options.

- color
- pretext
- title
- title_link
- author_name
- author_icon
- image_url
- thumb_url
- fields
- mrkdwn

### Access control

#### allow and deny by ip address.

```
export HUBOT_HTTP_IRC_DENY=192.168.0.1
```

deny access from 192.168.0.1.

```
export HUBOT_HTTP_IRC_DENY=192.168.0.
```

deny access from 192.168.0.0/24.


```
export HUBOT_HTTP_IRC_ALLOW=x.x.x.x
```

same as deny.

#### api key

```
export HUBOT_HTTP_IRC_API_KEY=YYYYYYYYY
```

please request with header 'HUBOT_HTTP_IRC_API_KEY'.

```
curl -X POST -H '-H 'HUBOT_HTTP_IRC_API_KEY:ZZZZZZZ' --data-urlencode message="hoge hoge." -d  room=%23foo http://YOUR_SERVER/http_irc
```

if you set allow or deny by ip address, it's condition will apply.


## jenkins-job-selector-by-git-branch

Do the job selected by the branch of git on jenkins

### Configuration

* JENKINS_JOBSELECTOR_CONFIG_FILE concfigration file path.

configuration file like this,

```
GIT_URL:
  target:
    - 'hoge'
    - 'fuga'
  auth:
    id: 'hoge'
    password: 'fuga'
    jobs:
      branchA: 'JENKIS_JOB_URL_A'
      branchB:
        - 'JENKIS_JOB_URL_A'
        - 'JENKIS_JOB_URL_B'
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
TARGET1:
  ACTION1:
    command: "/path/to/cmd1 ACTION1"
    user:
      - "foo"
      - "bar"
    message: "/path/to/cmd1 ACTION1 is executed."

  ACTION2:
    command: "/path/to/cmd1 ACTION2"
    user:
      - "foo"
    message: "/path/to/cmd1 ACTION2 is executed."

TARGET2:
  ACTION1:
    command: "/path/to/cmd2 ACTION1"
    user:
      - "foo"
      - "bar"
    message: "/path/to/cmd2 ACTION1 is executed."
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
