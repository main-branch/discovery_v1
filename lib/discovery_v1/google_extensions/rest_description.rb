# frozen_string_literal: true

require 'google/apis/discovery_v1'
require 'discovery_v1'

# Google extensions
module Google
  # Google::Apis extensions
  module Apis
    # Google::Apis::DiscoveryV1 extensions
    module DiscoveryV1
      # Extensions to the Google::Apis::DiscoveryV1::RestDescription class
      #
      # @example
      #   require 'discovery_v1/google_extensions'
      #   rest_description = DiscoveryV1.discovery_service.get_rest_api('sheets', 'v4')
      #   schema = 'batch_update_spreadsheet_request'
      #
      #   # This is a valid object for the schema -- you'll probably have something
      #   # more interesting
      #   object = { 'requests' => [] }
      #
      #   # These are the extensions:
      #   rest_description.validate_object(schema_name:, object: { 'requests' => [] })
      #   rest_description.object_schema_names #=> ["add_banding_request", "add_banding_response", ...]
      #
      # @api public
      #
      class RestDescription
        # Validate the object using the named JSON schema
        #
        # The JSON schemas are loaded from the Google Disocvery API. The schemas names are
        # returned by `DiscoveryV1.api_object_schema_names`.
        #
        # @example
        #   schema_name = 'batch_update_spreadsheet_request'
        #   object = { 'requests' => [] }
        #   DiscoveryV1.validate_api_object(schema_name:, object:)
        #
        # @param schema_name [String] the name of the schema to validate against
        # @param object [Object] the object to validate
        # @param logger [Logger] the logger to use for logging error, info, and debug message
        #
        # @raise [RuntimeError] if the object does not conform to the schema
        #
        # @return [void]
        #
        def validate_object(schema_name:, object:, logger: Logger.new(nil))
          ::DiscoveryV1::Validation::ValidateObject.new(rest_description: self, logger:).call(schema_name:, object:)
        end

        # List the names of the schemas available to use in the Google Discovery V1 API
        #
        # @example List the name of the schemas available
        #   rest_description = DiscoveryV1.discovery_service.get_rest_api('sheets', 'v4')
        #   DiscoveryV1.api_object_schema_names #=> ["add_banding_request", "add_banding_response", ...]
        #
        # @param logger [Logger] the logger to use for logging error, info, and debug message
        #
        # @return [Array<String>] the names of the schemas available
        #
        def object_schema_names(logger: Logger.new(nil))
          ::DiscoveryV1::Validation::LoadSchemas.new(rest_description: self, logger:).call.keys.sort
        end
      end
    end
  end
end
