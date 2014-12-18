# Description
#   A Hubot script for sending a message to yourself seven days later.
#
# Configuration:
#   None
#
# Commands:
#   hubot 7d add <message> - reserve the sending message
#   hubot 7d list - list reserved messages
#
# Author:
#   bouzuya <m@bouzuya.net>

moment = require 'moment'

module.exports = (robot) ->
  key = '7days-later'

  robot.respond /7d add (\S+)$/, (msg) ->
    message = msg.match[1]
    messages = robot.brain.get(key) ? []
    i = { room: msg.envelope.room, at: moment().add(7, 'days'), message }
    messages.push i
    robot.brain.set(key, messages)
    msg.send "#{i.at.format('YYYY-MM-DD HH:mm')} #{i.message}"

  robot.respond /7d list$/, (msg) ->
    messages = robot.brain.get(key) ? []
    message = messages.sort (a, b) ->
      if a.at.isSame(b.at)
        0
      else if a.at.isBefore(b.at)
        -1
      else
        1
    .map (i) ->
      "#{i.at.format('YYYY-MM-DD HH:mm')} #{i.message}"
    .join '\n'
    msg.send message

  watch = ->
    setTimeout ->
      messages = robot.brain.get(key) ? []
      now = moment()
      targets = messages.filter (i) -> i.at.isBefore(now)
      newMessages = messages.filter (i) -> !i.at.isBefore(now)
      if messages.length isnt newMessages.length
        robot.brain.set(key, newMessages)
      targets.forEach (i) ->
        robot.messageRoom i.room, i.message
      watch()
    , 60000

  watch()
