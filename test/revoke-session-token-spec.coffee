_ = require 'lodash'
mongojs = require 'mongojs'
redis = require 'fakeredis'
moment = require 'moment'
Cache = require 'meshblu-core-cache'
Datastore = require 'meshblu-core-datastore'
redis  = require 'fakeredis'
RevokeSessionToken = require '../'
JobManager = require 'meshblu-core-job-manager'
uuid = require 'uuid'

describe 'RevokeSessionToken', ->
  beforeEach (done) ->
    @redisKey = uuid.v1()
    @pepper = 'im-a-pepper-too'
    @pubSubKey = uuid.v1()
    @cache = new Cache client: redis.createClient(@redisKey)
    @uuidAliasResolver = resolve: (uuid, callback) => callback(null, uuid)
    @jobManager = new JobManager
      client: _.bindAll redis.createClient @pubSubKey
      timeoutSeconds: 1
    @datastore = new Datastore
      database: mongojs('meshblu-core-task-update-device')
      moment: moment
      collection: 'devices'

    @datastore.remove done

  beforeEach ->
    @sut = new RevokeSessionToken {@datastore, @uuidAliasResolver, @jobManager, @pepper, @cache}

  describe '->do', ->
    beforeEach (done) ->
      @datastore.insert {uuid: 'spiral', meshblu: tokens: {'T/GMBdFNOc9l3uagnYZSwgFfjtp8Vlf6ryltQUEUY1U=':{}}}, done

    describe 'when the device exists in the datastore', ->
      beforeEach (done) ->
        request =
          metadata:
            responseId: 'used-as-biofuel'
            auth:
              uuid: 'spiral'
              token: 'the-environment'
            toUuid: 'spiral'
          rawData: '{"token":"abc123"}'

        @sut.do request, (error, @response) => done error

      it 'should respond with a 204', ->
        expect(@response.metadata.code).to.equal 204
