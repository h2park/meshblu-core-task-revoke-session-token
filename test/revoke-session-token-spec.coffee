_                  = require 'lodash'
mongojs            = require 'mongojs'
Datastore          = require 'meshblu-core-datastore'
RevokeSessionToken = require '../'

describe 'RevokeSessionToken', ->
  beforeEach (done) ->
    @pepper = 'im-a-pepper'
    @uuidAliasResolver = resolve: (uuid, callback) => callback(null, uuid)
    database = mongojs 'meshblu-core-task-update-token', ['tokens']
    @datastore = new Datastore {
      database,
      collection: 'tokens'
    }
    database.tokens.remove done

  beforeEach ->
    @sut = new RevokeSessionToken {@datastore, @uuidAliasResolver, @pepper}

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
