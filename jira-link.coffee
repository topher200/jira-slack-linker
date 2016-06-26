# Description:
#   Responds with a link to the JIRA ticket for any WordStream-style tickets.
#
#   Listens for anyone to mention a PPC-12345 style ticket. We don't match
#   unless preceded by a space or Slack formatting charactor (so we don't match
#   on URLs).
#
#   Will not respond to the same ticket number for at least 10 minutes (to
#   reduce spam).
#
# Dependencies:
#   hubot-redis-brain (built in)
#
# Commands:
#   PPC-<Issue ID>: Links to the JIRA ticket page. 10 minute cooldown
#
# Author:
#   t.brown@wordstream.com
#
# Version:
#   1.3
module.exports = (robot) ->
  robot.hear /[\s|`|\"|\(|~|\*](PPC-\d+)/g, (res) ->
    responseList = []
    for ticketNumber in res.match
      # We matched on an extra char above (probably a space), so remove it
      ticketNumber = ticketNumber.slice(1)
      # Only respond if we haven't responded to this ticket in 10 minutes
      if (not robot.brain.get(ticketNumber) or
          robot.brain.get(ticketNumber) + 600000 < Date.now())
        robot.brain.set ticketNumber, Date.now()
        responseList.push(
          "<https://wordstream.atlassian.net/browse/#{ticketNumber}|#{ticketNumber}>")
    # Don't send a message if we have no responses
    return unless responseList.length
    # Build all the responses into one post
    console.log("Sending response: " + responseList)
    robot.emit 'slack.attachment',
      message: res.message,
      content: {
        text: responseList.join("\n")
      }
