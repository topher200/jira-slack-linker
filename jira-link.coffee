# Description:
#   Responds with a link to the JIRA ticket for any WordStream-style tickets.
#
#   Listens for anyone to mention a PPC-12345 style ticket.
#
#   Will not respond to the same ticket number in the same channel for at least
#   10 minutes (to reduce spam).
#
#   Posts a link to the ticket and the ticket's summary string.
#
# Dependencies:
#   async
#   jira-client
#
# Commands:
#   PPC-<Issue ID>: Links to the JIRA ticket page. 10 minute cooldown
#
# Author:
#   t.brown@wordstream.com
#
# Version:
#   2.0

async = require('async')
JiraApi = require('jira-client')

config = {
  url: process.env.JIRA_URL,
  username: new Buffer(process.env.JIRA_USERNAME, 'base64').toString('ascii').trim(),
  password: new Buffer(process.env.JIRA_PASSWORD, 'base64').toString('ascii').trim(),
  host: process.env.JIRA_HOST
};

console.log(config)

jira = new JiraApi({
    protocol: 'https',
    host: config.host,
    username: config.username,
    password: config.password,
    apiVersion: '2'
});

sleep = (ms) ->
  start = new Date().getTime()
  continue while new Date().getTime() - start < ms

buildResponse = (robot, room) ->
  (ticketNumber, callback) ->
    ticketNumberInChannel = ticketNumber + ' - ' + room
    console.log 'Processing ' + ticketNumberInChannel
    # Only respond if we haven't responded to this ticket in 10 minutes
    if (not robot.brain.get(ticketNumberInChannel) or
        robot.brain.get(ticketNumberInChannel) + 600000 < Date.now())
      robot.brain.set ticketNumberInChannel, Date.now()
    jira.findIssue ticketNumber
      .then (issue) ->
        response = (
            "<https://wordstream.atlassian.net/browse/#{ticketNumber}|#{ticketNumber}>: #{issue.fields.summary}")
        return callback(null, response)
      .catch (err) ->
        console.error 'Received jira error on ' + ticketNumber + '. error: ' + err.statusCode
        return callback(null, null)  # We don't return error, because that would stop every job

module.exports = (robot) ->
  robot.hear /(PPC-\d+)/g, (res) ->
    responseList = []
    async.map res.match, buildResponse(robot, res.message.room), (_, messages) ->
      # We ignore errors, and just filter out the ones that didn't finish
      responseList = messages.filter((v) -> v != null)
      # Don't send a message if we have no responses
      if !responseList.length
        console.log 'could not build a response'
        return
      # Build all the responses into one post
      console.log "Sending jira link message: \n" + responseList.join("\n")
      robot.emit 'slack.attachment',
        message: res.message,
        content: {
          text: responseList.join("\n"),
          fallback: ''
        }
