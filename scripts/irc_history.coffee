# Description:
#   Allows Hubot to store a recent chat history for services like IRC that
#   won't do it for you.
#
# Dependencies:
#   None
#
# Configuration:
#   HUBOT_HISTORY_LINES
#
# Commands:
#   hubot show history [<lines>] - Shows <lines> of history, otherwise all history
#   hubot clear history - Clears the history
#
# Author:
#   wubr (modified for IRC by mattetti)

class History
  constructor: (@robot, @keep) ->
    @cache = []
    @robot.brain.on 'loaded', =>
      if @robot.brain.data.history
        @robot.logger.info "Loading saved chat history"
        @cache = @robot.brain.data.history

  add: (message) ->
    @cache.push message
    while @cache.length > @keep
      @cache.shift()
    @robot.brain.data.history = @cache

  show: (lines) ->
    if (lines > @cache.length)
      lines = @cache.length
    reply = 'Showing ' + lines + ' lines of history:\n'
    reply = reply + @entryToString(message) + '\n' for message in @cache[-lines..]
    return reply

  entryToString: (event) ->
    return '[' + event.hours + ':' + event.minutes + '] ' + event.name + ': ' + event.message

  clear: ->
    @cache = []
    @robot.brain.data.history = @cache

class HistoryEntry
  constructor: (@name, @message) ->
    @time = new Date()
    @hours = @time.getHours()
    @minutes = @time.getMinutes()
    if @minutes < 10
      @minutes = '0' + @minutes

module.exports = (robot) ->

  options = 
    lines_to_keep:  process.env.HUBOT_HISTORY_LINES

  unless options.lines_to_keep
    options.lines_to_keep = 50

  history = new History(robot, options.lines_to_keep)

  robot.hear /(.*)/i, (msg) ->
    historyentry = new HistoryEntry(msg.message.user.name, msg.match[1])
    history.add historyentry

  robot.respond /show history\s*(\d+)?/i, (msg) ->
    if msg.match[1]
      lines = msg.match[1]
    else
      lines = history.keep
    reply_to =  msg.message.user.name
    msg.send "Sending room history to " + reply_to + " via PM"
    console.log "sending a history PM to " + reply_to
    robot.adapter.reply { user: { reply_to: reply_to, name: reply_to }}, history.show(lines)

  robot.respond /clear history/i, (msg) ->
    msg.send "Ok, I'm clearing the history."
    history.clear()