_    = require 'lodash'
http = require 'http'
TokenManager = require 'meshblu-core-manager-token'

class CreateSessionToken
  constructor: ({@uuidAliasResolver,@cache,@datastore,@pepper}) ->
    @tokenManager = new TokenManager {@datastore,@cache,@pepper,@uuidAliasResolver}

  _doCallback: (request, code, callback) =>
    response =
      metadata:
        responseId: request.metadata.responseId
        code: code
        status: http.STATUS_CODES[code]
    callback null, response

  do: (request, callback) =>
    {toUuid, messageType, options} = request.metadata
    {token} = JSON.parse request.rawData

    @tokenManager.revokeToken {uuid: toUuid, token}, (error, revoked) =>
      return callback error if error?
      code = 204
      code = 422 unless revoked
      return @_doCallback request, code, callback

module.exports = CreateSessionToken
