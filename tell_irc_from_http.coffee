# Description
# #   "Simple path to have Hubot echo out anything in the message querystring for a given room."
# #
# # Dependencies:
# #   "querystring": "0.1.0"
# #
# # Configuration:
# #   None
# #
# # Commands:
# #   None
# #
# # URLs
# #   GET /hubot/tell_irc?message=<message>&room=<room>
# #
# # Author:
# #   Taiyu Fujii

querystring = require('querystring')

module.exports = (robot) ->
  robot.router.get "/hubot/tell_irc", (req, res) ->
    query = querystring.parse(req._parsedUrl.query)
    robot.send { room: "\##{query.room}" }, "#{query.message}"

    res.writeHead 200, {'Content-Type': 'text/plain'}
    res.end 'OK'
