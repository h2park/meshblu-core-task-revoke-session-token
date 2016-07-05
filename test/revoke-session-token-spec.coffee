_                  = require 'lodash'
mongojs            = require 'mongojs'
redis              = require 'fakeredis'
Cache              = require 'meshblu-core-cache'
Datastore          = require 'meshblu-core-datastore'
redis              = require 'fakeredis'
RevokeSessionToken = require '../'
JobManager         = require 'meshblu-core-job-manager'
uuid               = require 'uuid'

describe 'RevokeSessionToken', ->
  beforeEach (done) ->
    @redisKey = uuid.v1()
    @pepper = 'im-a-pepper'
    @cache = new Cache client: redis.createClient @redisKey
    @uuidAliasResolver = resolve: (uuid, callback) => callback(null, uuid)
    database = mongojs 'meshblu-core-task-update-token', ['tokens']
    @datastore = new Datastore {
      database,
      collection: 'tokens'
    }
    database.tokens.remove done

  beforeEach ->
    @sut = new RevokeSessionToken {@datastore, @uuidAliasResolver, @pepper, @cache}

  describe '->do', ->
    beforeEach (done) ->
      records = [
        {
          uuid: 'spiral'
          hashedToken: 'T/GMBdFNOc9l3uagnYZSwgFfjtp8Vlf6ryltQUEUY1U='
        }
        {
          uuid: 'spiral'
          hashedToken: 'bOT5i3r4bUXvG5owgEVUBOtnF30zyuShfocALDoi1HA='
        }
      ]
      @datastore.insert records, done

    beforeEach (done) ->
      @cache.set 'spiral:T/GMBdFNOc9l3uagnYZSwgFfjtp8Vlf6ryltQUEUY1U=', '', done

    beforeEach (done) ->
      @cache.set 'spiral:bOT5i3r4bUXvG5owgEVUBOtnF30zyuShfocALDoi1HA=', '', done

    describe 'when the token exists in the datastore', ->
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

      it 'should remove the session token', (done) ->
        @datastore.find { uuid: 'spiral' }, (error, records) =>
          return done error if error?
          expect(records).to.deep.equal [
            {
              uuid: 'spiral'
              hashedToken: 'bOT5i3r4bUXvG5owgEVUBOtnF30zyuShfocALDoi1HA='
            }
          ]
          done()

      it 'should not exist in the cache', (done) ->
        @cache.exists 'spiral:T/GMBdFNOc9l3uagnYZSwgFfjtp8Vlf6ryltQUEUY1U=', (error, exists) =>
          return done error if error?
          expect(exists).to.be.false
          done()

      it 'should have the other token in the cache', (done) ->
        @cache.exists 'spiral:bOT5i3r4bUXvG5owgEVUBOtnF30zyuShfocALDoi1HA=', (error, exists) =>
          return done error if error?
          expect(exists).to.be.true
          done()
