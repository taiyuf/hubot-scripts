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
    export HUBOT_IRC_MSG_TYPE="string"
    export HUBOT_IRC_MSG_LABEL="message"
    export HUBOT_IRC_FMT_LABEL="format"
    
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

if you want to tell the room '#test' on IRC server, room is '%23test'.

### GET

GET http://YOUR_SERVER/http_irc?message=hoge&room=%23test

ex)

    curl http://YOUR_SERVER/http_irc?message=hoge&room=%23test


### POST

POST /http_irc?room=<room> or POST /http_irc

    curl -X POST --data-urlencode message="hoge hoge." http://YOUR_SERVER/http_irc?room\=test
    
    curl -X POST --data-urlencode message="hoge hoge." -d  room=#foo http://YOUR_SERVER/http_irc


## read_rss

Simple RSS Reader for irc and group chat system.

### Configuration

* RSS_CONFIG_FILE: path to configuration file(json format).
* RSS_LABEL:       if you create many bots, you define a unique keyword.

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

* GITLAB_CONFIG_FILE: the path to configuration file.
* GITLAB_URL        : web site url of gitlab.

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

* JENKINS_NOTIFY_CONFIG_FILE concfigration file path.

configuration file like this,

IRC

    {
         "GIT_REPOSITORY": {"target": ["#hoge"],
                            ...,
                           }
    }

Other

    {
         "GIT_REPOSITORY": {"target": ["http://....."],
                            ...,
                           }
    }

* GIT_REPOSITORY: ex. ssh://GITLABUSER@GITLAB_URL/USER/PROJECT.git

* TARGET: channel name for IRC, or end point url for other group chat services.


### Usage

Put http://<HUBOT_URL>:<PORT>/hubot/jenkins-notify to your Jenkins


## jenkins-job-selector-by-git-branch

Do the job selected by the branch of git on jenkins

### Configuration

* JENKINS_JOBSELECTOR_CONFIG_FILE concfigration file path.

configuration file like this,

    {
       "GIT_URL": {
                      "target": ["hoge", "fuga"],
                      "auth": {"id": "hoge",
                               "password": "fuga"},
                      "jobs":{"branchA": "JENKIS_JOB_URL_A",
                              "branchB": "JENKIS_JOB_URL_A"}
                     }
    }

### Usage

Put http://<HUBOT_URL>:<PORT>/hubot/jenkins-jobselector to web hook at your git repository.


