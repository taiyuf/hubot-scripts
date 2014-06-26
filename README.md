hubot-scripts
=============

hubot scripts.

# Configuration

## Dependencies

  hubot-irc: "~0.2.2"

## Usage

Here is sample configuration. See https://github.com/nandub/hubot-irc.

### IRC

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

### HTTP_POST

    # basic
    export HUBOT_HOME=/home/hubot
    export NODE_PATH=${HUBOT_HOME}/node_modules
    export REDIS_URL="redis://127.0.0.1:6379"
    export PORT=19999
    
    # http_post
    export HUBOT_IRC_TYPE="http_post"
    export HUBOT_IRC_ROOMS="#dummy" # dummy text
    export HUBOT_IRC_SERVER="hoge"  # dummy text
    export HUBOT_IRC_HEADERS=${HUBOT_HOME}/headers.json # custom headers as json
    
    ${HUBOT_HOME}/bin/hubot -a irc

HUBOT_IRC_HEADERS:

    {
        "HEADER_NAME": "HEADER_VALUE"
    }


### idobata

    # basic
    export HUBOT_HOME=/home/hubot
    export NODE_PATH=${HUBOT_HOME}/node_modules
    export REDIS_URL="redis://127.0.0.1:6379"
    export PORT=19999
    
    # idobata
    export HUBOT_IRC_TYPE="idobata"
    export HUBOT_IRC_ROOMS="#dummy" # dummy text
    export HUBOT_IRC_SERVER="hoge"  # dummy text
    export HUBOT_IRC_HEADERS=${HUBOT_HOME}/headers.json # custom headers as json
    
    ${HUBOT_HOME}/bin/hubot -a irc

HUBOT_IRC_HEADERS:

    {
        "X-API-Token": "YOUR_API_TOKEN"
    }


### chatwork

    # basic
    export HUBOT_HOME=/home/hubot
    export NODE_PATH=${HUBOT_HOME}/node_modules
    export REDIS_URL="redis://127.0.0.1:6379"
    export PORT=19999
    
    # chatwork
    export HUBOT_IRC_TYPE="chatwork"
    export HUBOT_IRC_ROOMS="#dummy" # dummy text
    export HUBOT_IRC_SERVER="hoge"  # dummy text
    export HUBOT_IRC_HEADERS=${HUBOT_HOME}/headers.json # custom headers as json
    
    ${HUBOT_HOME}/bin/hubot -a irc

HUBOT_IRC_HEADERS:

    {
        "X-ChatWorkToken": "YOUR_TOKEN",
        "Content-Type": "text/plain"
    }

# Modules

## http_irc

Simple path to have Hubot echo out anything in the message querystring for a given room.

If you want to tell '#test' room,

http://YOUR_SERVER/http_irc?message=hoge&room=test

This version do not support the POST method.

## read_rss

Simple RSS Reader for irc and group chat system.

### Configuration

RSS_CONFIG_FILE: path to configuration file(json format).
RSS_LABEL:       if you create many bots, you define a unique keyword.

You need to write configuration file as json format.

    {
      "keyword1": {"feed": {"url": "http://...."},
                   "target": ["#hoge", "#fuga"]},    # IRC
      "keyword2": {"feed": {"url": "http://...",
                            "id": "user",
                            "password": "password"},
                   "target": ["http://....", "http://...."]}      # Other
    }

url, room(idobata channel's url) fields are required. if the site require the basic
authentication, you need to set id, password fields.

## gitlab

Post gitlab related events using gitlab hooks

### Configuration

GITLAB_CONFIG_FILE: the path to configuration file.
GITLAB_URL        : web site url of gitlab.

configuration file like below,

IRC
    {
         "target": ["#hoge"]
     }

Other
    {
         "target": ["http://....."]
     }

### Usage

Put http://<HUBOT_URL>:<PORT>/gitlab/system as your system hook
Put http://<HUBOT_URL>:<PORT>/gitlab/web as your web hook (per repository)

## jenkins-notify

Notifies about Jenkins build errors via Jenkins Notification Plugin.

### Configuration

JENKINS_NOTIFY_CONFIG_FILE concfigration file path.

configuration file like this,

IRC
    {
         "target": ["#hoge"]
     }

Other
    {
         "target": ["http://....."]
     }

### Usage

Put http://<HUBOT_URL>:<PORT>/hubot/jenkins-notify to your Jenkins
