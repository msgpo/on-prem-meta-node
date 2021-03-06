# Official On-Prem Meta REST API client and helper library

[![GitHub release](https://img.shields.io/github/release/on-prem/on-prem-meta-node.svg)](https://github.com/on-prem/on-prem-meta-node) ![Build status](https://github.com/on-prem/on-prem-meta-node/workflows/Node%20CI/badge.svg?branch=master)

  1. [Requirements](#requirements)
  2. [Installation](#installation)
  3. [Environment](#environment)
  4. [Functions](#functions)
  5. [Usage](#usage)
  6. [Testing](#testing)
  7. [License](#license)

# Requirements

  * NodeJS `v8.x` to `v12.x` (tested)
  * This library requires the `needle` and `form-data` node modules

# Installation

```
npm install @on-prem/on-prem-meta
```

or

```
git clone https://github.com/on-prem/on-prem-meta-node
cd on-prem-meta-node
npm install
```

# Environment

**Required** environment variables:

* `export ON_PREM_META_HOST=meta.yourdomain.com:443`
* `export ON_PREM_META_APITOKEN=yourtoken`

**Optional** environment variables:

If you're using a self-signed certificate:

* `export ON_PREM_META_INSECURE=true`

To manage the _Admin API_ instead of the _Meta API_:

* `export ON_PREM_META_PREFIX=admin`

To obtain an _On-Prem Meta_ OVA, please visit [https://on-premises.com](https://on-premises.com)

# Functions

The following functions are exported:

* `makeSHA256()` to generate an SHA256 string
* `makeHMAC()` to generate an SHA256 HMAC from a string and key
* `buildRequest()` to generate a request object to be sent to the `apiCall()` function
* `apiCall()` to send the actual request data to the Meta API

The following helper functions are exported:

* `getVersion()` to get the version of the Meta or Admin appliance
* `buildOVA()` to build an OVA through the Meta API
* `getStatus()` to obtain the status of an OVA build
* `pollStatus()` to poll the status of an OVA build (every 5 seconds)
* `getDownloads()` to obtain the list of download files for an OVA build
* `cancelBuild()` to cancel a running OVA build

See the usage docs below.

# Usage

1. [CoffeeScript](#coffeescript)
2. [JavaScript](#JavaScript)

## CoffeeScript

#### 1. Require the library as you would any other node module:

```coffee
meta = require 'on-prem-meta'
```

or

```coffee
meta = require './src/on-prem-meta'
```

#### 2. Define your request parameters

```coffee
apiParams =
  method: 'GET'
  endpoint: 'settings/license'
```

#### 3. Build an API request and make an API call

```coffee
meta.buildRequest apiParams, (error, result) =>
  unless error
    meta.apiCall result, (err, res, data) ->
      console.log "ERROR:", err
      console.log "RESULT:", res
      console.log "DATA:", data
```

### Examples

#### Make a `GET` request with query parameters (ex: `&time=day`)

```coffee
apiParams =
  method: 'GET'
  endpoint: 'audit'
  query:
    time: 'day'
meta.buildRequest apiParams, (error, result) =>
  unless error
    meta.apiCall result, (err, res, data) ->
      console.log data

coffee> {
  logs: [
    {
      logdate: '1574834282.732987162',
      id: '287e10307425d845',
      location: 'web',
      user: 'admin',
      action: 'builds.create',
      data: '1574834281.966265128'
    }
  ],
  num: 1
}
```

#### Make a `POST` request with a file upload and query parameters

```coffee
apiParams =
  method: 'POST'
  endpoint: 'settings/license'
  files:
    settings:
      filename: 'license.asc'
      data: fs.readFileSync('./path/to/license.asc')
  query:
    id: 1
meta.buildRequest apiParams, (error, result) =>
  unless error
    meta.apiCall result, (err, res, data) ->
      console.log data

coffee> { Status: '200 OK' }
```

#### Change a NodeJS `http.request()` option (example: `family` (for IPv6))

```coffee
meta.options.agent = new https.Agent { family: 6 }
meta.buildRequest undefined, (error, result) =>
  unless error
    meta.apiCall result, (err, res, data) ->
      console.log data
```

### Helper examples

The following helper functions are designed to simplify API calls and return simple string results

#### buildOVA() - Build an OVA (returns the builddate)

```coffee
apiParams =
  repo_name: 'your-appliance'
  ova_type: 'server'
  export_disks: 'raw,qcow2'

meta.buildOVA "/path/to/your/app.tcz", apiParams, (err, res) ->
  if err
    console.error err
    process.exit 1
  else
    console.log res

coffee> 1574834281.966265128
```

#### pollStatus() - Poll the status of an OVA (returns the status)

```coffee
meta.pollStatus '1574834281.966265128', undefined, (err, res) ->
  if err
    console.error err
    process.exit 1
  else
    console.log res

coffee> success
```

#### getDownloads() - Get the list of download URLs (returns a list of URLs)

```coffee
meta.getDownloads '1574834281.966265128', (err, res) ->
  if err
    console.error err
    process.exit 1
  else
    console.log res

coffee> https://yourdomain.com:443/downloads/build-1574834281.966265128/your-appliance-v1.2.3-release.ova
```

#### cancelBuild() - Cancel an OVA build (returns OK)

```coffee
meta.cancelBuild '1574834281.966265128', (err, res) ->
  if err
    console.error err
    process.exit 1
  else
    console.log res

coffee> OK
```

## JavaScript

#### 1. Require the library as you would any other node module:

```js
meta = require('on-prem-meta');
```

or

```js
meta = require('./lib/on-prem-meta');
```

#### 2. Define your request parameters

```js
var apiParams = { method: 'GET', endpoint: 'settings/license' };
```

#### 3. Build an API request and make an API call

```js
meta.buildRequest(apiParams, (error, result) => {
  if (!error) {
    return meta.apiCall(result, function(err, res, data) {
      console.log("ERROR:", err);
      console.log("RESULT:", res);
      return console.log("DATA:", data);
    });
  }
});
```

### Examples

#### Make a `GET` request with query parameters (ex: `&time=day`)

```js
apiParams = {
  method: 'GET',
  endpoint: 'audit',
  query: {
    time: 'day'
  }
};

meta.buildRequest(apiParams, (error, result) => {
  if (!error) {
    return meta.apiCall(result, function(err, res, data) {
      return console.log(data);
    });
  }
});
```

#### Make a `POST` request with a file upload and query parameters

```js
apiParams = {
  method: 'POST',
  endpoint: 'settings/license',
  files: {
    settings: {
      filename: 'license.asc',
      data: fs.readFileSync('./path/to/license.asc')
    }
  },
  query: { id: 1 }
};
meta.buildRequest(apiParams, (error, result) => {
  if (!error) {
    return meta.apiCall(result, function(err, res, data) {
      return console.log(data);
    });
  }
});
```

#### Change a NodeJS `http.request()` option (example: `family` (for IPv6))

```js
meta.options.agent = new https.Agent({ family: 6 });
meta.buildRequest(void 0, (error, result) => {
  if (!error) {
    return meta.apiCall(result, function(err, res, data) {
      return console.log(data);
    });
  }
});
```

### Helper examples

The following helper functions are designed to simplify API calls and return simple string results

#### buildOVA() - Build an OVA (returns the builddate)

```js
apiParams = {
  repo_name: 'your-appliance',
  ova_type: 'server',
  export_disks: 'raw,qcow2'
};

meta.buildOVA("/path/to/your/app.tcz", apiParams, function(err, res) {
  if (err) {
    console.error(err);
    return process.exit(1);
  } else {
    return console.log(res);
  }
});
```

#### pollStatus() - Poll the status of an OVA (returns the status)

```js
meta.pollStatus('1574834281.966265128', void 0, function(err, res) {
    if (err) {
      console.error(err);
      return process.exit(1);
    } else {
      return console.log(res);
    }
  });
```

#### getDownloads() - Get the list of download URLs (returns a list of URLs)

```js
meta.getDownloads('1574834281.966265128', function(err, res) {
    if (err) {
      console.error(err);
      return process.exit(1);
    } else {
      return console.log(res);
    }
  });
```

#### cancelBuild() - Cancel an OVA build (returns OK)

```js
meta.cancelBuild('1574941961.314614280', function(err, res) {
    if (err) {
      console.error(err);
      return process.exit(1);
    } else {
      return console.log(res);
    }
  });
```

# Testing

To run the tests, type:

```
npm test
```

# License

[MIT License](LICENSE)

Copyright (c) 2019 Alexander Williams, Unscramble <license@unscramble.jp>
