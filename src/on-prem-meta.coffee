#   Official On-Prem Meta REST API client and helper library
#   https://on-premises.com
#
#   Copyright (c) 2019 Alex Williams, Unscramble <license@unscramble.jp>
#   MIT Licensed

createHash = require('crypto').createHash
createHmac = require('crypto').createHmac
needle     = require 'needle'
formData   = require 'form-data'
fs         = require 'fs'

needle.defaults
  user_agent: 'nodeclient-on-prem-meta/1.5.0'
  response_timeout: 10000 # 10 seconds

exports.makeSHA256 = (string) ->
  createHash('sha256')
    .update(string)
    .digest 'hex'

exports.makeHMAC = (string, key) ->
  createHmac('sha256', key)
    .update(string)
    .digest 'hex'

# Global variables
settings =
  prefix:    process.env.ON_PREM_META_PREFIX || "meta" # example: admin
  host:      process.env.ON_PREM_META_HOST || throw "Environment variable 'ON_PREM_META_HOST' required" # example: meta.yourdomain.com:443
  insecure:  if process.env.ON_PREM_META_INSECURE is "true" then false else true
  tokenhash: this.makeSHA256 process.env.ON_PREM_META_APITOKEN || throw "Environment variable 'ON_PREM_META_APITOKEN' required" # example: yourtoken

options =
  rejectUnauthorized: settings.insecure

exports.settings = settings
exports.options  = options

exports.buildRequest = (params = {method: 'GET', endpoint: 'version'}, callback) ->
  endpoint = "/api/v1/#{settings.prefix}/#{params.endpoint}"

  switch params.method.toUpperCase()
    when 'GET'
      data = params.query ? {}
      data.hash = this.makeHMAC("#{params.method.toUpperCase()}#{endpoint}", settings.tokenhash)

      return callback null,
        method: params.method.toUpperCase()
        uri: "https://#{settings.host}#{endpoint}"
        data: data
        options: options

    when 'POST'
      data = new formData()
      data.append 'hash', this.makeHMAC("#{params.method.toUpperCase()}#{endpoint}", settings.tokenhash)
      data.append name, val for name, val of params.query                     # append params
      data.append file, val.data, val.filename for file, val of params.files  # append files
      options.headers = data.getHeaders()

      return callback null,
        method: params.method.toUpperCase()
        uri: "https://#{settings.host}#{endpoint}"
        data: data
        options: options

    else
      return callback new Error 'Invalid request method'

exports.apiCall = (params, callback) ->
  req = needle.request params.method,
    params.uri
    params.data
    params.options
    (err, res, data) ->
      return callback err, res, data

# returns a callback with the version of the API
exports.getVersion = (callback) =>
  this.buildRequest undefined, (error, result) =>
    unless error
      this.apiCall result, (err, res, data) =>
        unless err
          callback data.version

# returns a callback with an error in arg1, or the builddate in arg2
# the error is an Error object if non-HTTP related
# the error is the request result if 404 or other HTTP error code (4xx or 5xx)
exports.buildOVA = (application, parameters, callback) =>
  this.getVersion (version) =>
    apiParams =
      method: 'POST'
      endpoint: 'builds'
      files:
        app:
          filename: 'app.tcz'
          data: fs.readFileSync(application)
      query: parameters

    this.buildRequest apiParams, (error, result) =>
      callback error if error
      this.apiCall result, (err, res, data) ->
        if err
          callback new Error err
        else if res.statusCode is 202 and res.statusMessage is 'Accepted'
          if version >= '1.13.1'
            callback null, data.builddate # builddate added in v1.13.1
          else
            callback null, data.Location.split("=")[1] # parse the Location to get the builddate
        else
          callback data

exports.getStatus = (build, callback) =>
  this.getVersion (version) =>
    apiParams =
      method: 'GET'
      endpoint: 'builds/status'
      query:
        builddate: build
        log: 0 if version >= '1.13.1' # log parameter added in v1.13.1

    this.buildRequest apiParams, (error, result) =>
      callback error if error
      this.apiCall result, (err, res, data) ->
        if err
          callback new Error err
        else if res.statusCode is 202 and res.statusMessage is 'Accepted'
          callback null, { status: 'queued' }
        else if res.statusCode is 200 and data
          callback null, data
        else
          callback data

# returns a callback with and error in arg1, or the status in arg2
# the error is an Error object if non-HTTP related
# the error is the request result if 404 or other HTTP error code (4xx or 5xx)
exports.pollStatus = (build, status = {}, callback) =>
  switch status.status
    when 'success', 'failed'
      return status.status
    else
      this.getStatus build, (err, res) =>
        if err
          callback err
        else
          if res.status is 'success'
            callback null, this.pollStatus build, res
          else if res.status is 'failed'
            callback null, this.pollStatus build, res
          else
            run = () =>
              this.pollStatus build, res, (error, result) ->
                callback error if error
                callback null, result

            # wait 5 seconds between each request
            setTimeout run, 5000

# returns a callback with an error in arg1, or the list of downloads in arg2
# the error is an Error object if non-HTTP related
# the error is the request result if 404 or other HTTP error code (4xx or 5xx)
exports.getDownloads = (build, callback) =>
  apiParams =
    method: 'GET'
    endpoint: 'downloads'
    query:
      builddate: build

  this.buildRequest apiParams, (error, result) =>
    callback error if error
    this.apiCall result, (err, res, data) ->
      if err
        callback new Error err
      else if res.statusCode is 200 and res.statusMessage is 'OK'
        downloads = for i, url in data.downloads
          "https://#{settings.host}#{i.url}"
        callback null, downloads.join('\n')
      else
        callback data

# returns a callback with an error in arg1, or 'OK' in arg2
# the error is an Error object if non-HTTP related
# the error is the request result if 404 or other HTTP error code (4xx or 5xx)
exports.cancelBuild = (build, callback) =>
  apiParams =
    method: 'POST'
    endpoint: 'builds/cancel'
    query:
      builddate: build

  this.buildRequest apiParams, (error, result) =>
    callback error if error
    this.apiCall result, (err, res, data) ->
      if err
        callback new Error err
      else if res.statusCode is 200 and res.statusMessage is 'OK'
        callback null, res.statusMessage
      else
        callback data
