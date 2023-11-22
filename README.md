# DiscoveryV1

[![Gem Version](https://badge.fury.io/rb/discovery_v1.svg)](https://badge.fury.io/rb/discovery_v1)
[![Documentation](https://img.shields.io/badge/Documentation-Latest-green)](https://rubydoc.info/gems/discovery_v1/)
[![Change Log](https://img.shields.io/badge/CHANGELOG-Latest-green)](https://rubydoc.info/gems/discovery_v1/file/CHANGELOG.md)
[![Build Status](https://github.com/main-branch/discovery_v1/workflows/CI%20Build/badge.svg?branch=main)](https://github.com/main-branch/discovery_v1/actions?query=workflow%3ACI%20Build)
[![Maintainability](https://api.codeclimate.com/v1/badges/aeebc016487c5cad881e/maintainability)](https://codeclimate.com/github/main-branch/discovery_v1/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/aeebc016487c5cad881e/test_coverage)](https://codeclimate.com/github/main-branch/discovery_v1/test_coverage)

Unofficial helpers and extensions for the Google Discovery V1 API

* [Installation](#installation)
* [Examples](#examples)
* [Important links](#important-links)
  * [DiscoveryV1 documenation](#discoveryv1-documenation)
  * [General API documentation](#general-api-documentation)
  * [Ruby implementation of the Discovery API](#ruby-implementation-of-the-discovery-api)
* [Usage](#usage)
  * [Obtaining a DiscoveryService](#obtaining-a-discoveryservice)
  * [Downloading an API discovery document](#downloading-an-api-discovery-document)
  * [Validating API objects](#validating-api-objects)
  * [Google Extensions](#google-extensions)
    * [RestDescription Extensions](#restdescription-extensions)
* [Development](#development)
* [Contributing](#contributing)
* [License](#license)
* [Code of Conduct](#code-of-conduct)

## Installation

Install the gem and add to the application's Gemfile by executing:

```shell
bundle add discovery_v1
```

If bundler is not being used to manage dependencies, install the gem by executing:

```shell
gem install discovery_v1
```

## Examples

TODO

## Important links

### DiscoveryV1 documenation

This Gem's YARD documentation is hosted on [rubydoc.info](https://rubydoc.info/gems/discovery_v1/).

### General API documentation

* [Google Discovery API Overview](https://developers.google.com/discovery/v1/getting_started)
* [Google Discovery API Reference](https://developers.google.com/discovery/v1/reference)

### Ruby implementation of the Discovery API

* [DiscoveryService Class](https://github.com/googleapis/google-api-ruby-client/blob/main/generated/google-apis-discovery_v1/lib/google/apis/discovery_v1/service.rb)
* [All Other Discovery Classes](https://github.com/googleapis/google-api-ruby-client/blob/main/generated/google-apis-discovery_v1/lib/google/apis/discovery_v1/classes.rb)

## Usage

[Detailed API documenation](https://rubydoc.info/gems/discovery_v1/) is hosted on rubygems.org.

### Obtaining a DiscoveryService

No credential file is needed to access the discovery service.

```Ruby
discovery_service = DiscoveryV1.discovery_service
```

### Downloading an API discovery document

The Discovery API provides a list of Google APIs and a machine-readable "Discovery
Document" for each API. Both capabilities are provided by
[`Google::Apis::DirectoryV1::DirectoryService`](https://rubydoc.info/gems/google-apis-discovery_v1/Google/Apis/DiscoveryV1/DiscoveryService)
instance methods:

* [`#list_apis`](https://rubydoc.info/gems/google-apis-discovery_v1/Google/Apis/DiscoveryV1/DiscoveryService#list_apis-instance_method)
  returns the list of supported APIs
* [`#get_rest_api`](https://rubydoc.info/gems/google-apis-discovery_v1/Google/Apis/DiscoveryV1/DiscoveryService#get_rest_api-instance_method)
   returns the "discovery document" which is a description of a particular version
   of an api

Each discovery document includes schemas for the objects that can be passed as
parameters to methods in that API.

### Validating API objects

This gem can use the schemas that are part of a discovery document to validate
objects that parameters to an API method call.

This can be helpful to troubleshoot invalid requests since requests can become
very large and complex.

The [`DiscoveryV4.validate_object`](https://todo.com)
method can be used to validate a request object before an API call. This method
requires the following information:

1. the Discovery Document returned from `DirectoryService#get_read_api`
2. the name of the schema for the object being validated (must be one returned from `DirectoryService.object_schema_names`)
3. the object being validated

For example, in the Google Sheets API, speradsheets are often updated by calling
`SheetsService#batch_update_spreadsheet`. This API method requires a
`BatchUpdateSpreadsheetRequest` object.

Here is an example that builds a request to write the value 'A' to cell A1 but it
contains an error (see if you can spot the error):

```Ruby
require 'discovery_v1'

batch_update_spreadsheet_request = {
  requests: [
    {
      update_cells: {
        rows: [
          { values: [ { user_entered_value: { string_value: 'A' } } ] }
        ],
        fields: '*',
        start: { sheet_id: 0, row_index: '1', column_index: 'A' }
      }
    }
  ],
  response_include_grid_data: false
}

api_name = 'sheets'
api_version = 'v4'
discovery_service = DiscoveryV1.discovery_service
rest_description = discovery_service.get_rest_api(api_name, api_version)
schema_name = 'batch_update_spreadsheet_request'

begin
  DiscoveryV1.validate_object(rest_description:, schema_name:, object: batch_update_spreadsheet_request)
rescue => e
  puts e.message
end
```

Running this example shows the following output:

```Text
Object does not conform to batch_update_spreadsheet_request: value at `/requests/0/update_cells/start/row_index` is not an integer
```

The [`DiscoveryV1.validate_object`](https://rubydoc.info/gems/discovery_v1/DiscoveryV1#validate_object-class_method)
method can be used to validate objects prior to using them in a Google API request
described by the Discovery service.

This method takes a `schema_name` and an `object` to validate. Schema names for a
schema can be listed using
[`DiscoveryV1.object_schema_names`](https://rubydoc.info/gems/discovery_v1/DiscoveryV1#object_schema_names-class_method).

`validate_object` will either return `true` if `object` conforms to the schema OR it
will raise a RuntimeError noting where the object structure did not conform to
the schema. `RuntimeError#message` will give details about where the structure did
not conform.

### Google Extensions

The `DiscoveryV1::GoogleExtensions` module provides extensions to the `Google::Apis::DiscoveryV1`
modules and classes to simplify use of the SheetsV4 API.

These extensions are not loaded by default and are not required to use other parts
of this Gem. To enable these extension, you must:

```Ruby
require 'discovery_v1/google_extensions'
```

#### RestDescription Extensions

Convenience methods are been added to `Google::Apis::DiscoveryV1::RestDescription`:
* [RestDescription#object_schema_names](https://rubydoc.info/gems/discovery_v1/Google/Apis/DiscoveryV1/RestDescription#object_schema_names-instance_method):
  The names of the schemas defined by this `RestDescription`.
* [RestDescription#validate_object](https://rubydoc.info/gems/discovery_v1/Google/Apis/DiscoveryV1/RestDescription#validate_object-instance_method):
  Raises an error if the given object does not conform to the named schema.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/discovery_v1. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/discovery_v1/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the DiscoveryV1 project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/discovery_v1/blob/main/CODE_OF_CONDUCT.md).
