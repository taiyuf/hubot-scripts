hubot-scripts
=============

hubot scripts.

# http_irc

Simple path to have Hubot echo out anything in the message querystring for a given room.

If you want to tell '#test' room,

http://YOUR_SERVER/http_irc?message=hoge&room=test

This version do not support the POST method.

# read_rss

Simple RSS Reader for irc and group chat system.

## Configuration

RSS_CONFIG_FILE: path to configuration file(json format).
RSS_LABEL:       if you create many bots, you define a unique keyword.
RSS_TARGET_TYPE: "http_post" or "irc"


If you use the group chat system and post message by HTTP POST, you set "RSS_TARGET_TYPE" to "http_post", and configuration file like this,

    {
      "keyword1": {"feed": {"url": "http://...."},
                   "target": ["URL1"]},
      "keyword2": {"feed": {"url": "http://...",
                            "id": "user",
                            "password": "password"},
                   "target": ["URL1", "URL2"]}
    }

If you use the irc adapter of hubot, you set "type" is irc, and configuratio file like this,

    {
      "keyword1": {"feed": {"url": "http://...."},
                   "target": ["#hoge", "#fuga"]},
      "keyword2": {"feed": {"url": "http://...",
                            "id": "user",
                            "password": "password"},
                   "target": ["#hoge", "#foo"]}
    }

url, room(idobata channel's url) fields are required. if the site require the basic
authentication, you need to set id, password fields.

# gitlab

Post gitlab related events using gitlab hooks

## Configuration

GITLAB_CONFIG_FILE: the path to configuration file.

configuration file like below,

    {
         "type": "irc",
         "target": ["#hoge"],
         "headers": {"hoge": "fuga", ... } # optional
     }

## Usage

Put http://<HUBOT_URL>:<PORT>/gitlab/system as your system hook
Put http://<HUBOT_URL>:<PORT>/gitlab/web as your web hook (per repository)

# jenkins-notify

Notifies about Jenkins build errors via Jenkins Notification Plugin.

## Configuration

JENKINS_NOTIFY_CONFIG_FILE concfigration file path.

configuration file like this,

    {
       "type": "irc",
       "target": ["hoge", "fuga"],
       "headers": {"foo": "bar", ... }  # optional
    }

## Usage

Put http://<HUBOT_URL>:<PORT>/hubot/jenkins-notify to your Jenkins
