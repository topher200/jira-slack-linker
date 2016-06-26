Helper = require('hubot-test-helper')

# helper loads a specific script if it's a file
scriptHelper = new Helper('./jira-link.coffee')

Promise= require('bluebird')
co     = require('co')
expect = require('chai').expect

describe 'jira-link', ->

  beforeEach ->
    console.log 'building'
    @room = scriptHelper.createRoom()

  afterEach ->
    @room.destroy()

  context 'user mentions JIRA issue', ->
    it 'should send a slack event', ->
      response = null
      @room.robot.on 'slack.attachment', (event) ->
        response = event.content
      co =>
        yield @room.user.say 'alice', 'working on PPC-123 and PPC-15501, but not /PPC-12343'
        yield new Promise.delay(1900)  # give our API calls some time

        expect(response.text).to.include("PPC")
