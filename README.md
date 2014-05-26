hubot-scripts
=============

hubot scripts.

# hubot_irc

Simple path to have Hubot echo out anything in the message querystring for a given room.

If you want to tell '#test' room,

http://YOUR_SERVER/http_irc?message=hoge&room=test

This version do not support the POST method.

# read_rss_for_irc

Simple RSS Reader for irc.

You need to configure 'RSS_CONFIG_FILE' value, and it should be as json format.

like this,

{
  "rss feed1": {"url": "http://....",
                "room": ["#hoge", "#fuga"]},
  "rss feed2": {"url": "http://...",
                "id": "user",
                "password": "password",
                "room": ["#hoge", "#fuga"]}
}

url, room(irc channel) fields are required. if the site require the basic
authentication, you need to set id, password fields.


