# frozen_string_literal: true

require 'google/apis/discovery_v1'

require_relative 'discovery_v1/version'
require_relative 'discovery_v1/validation'

# Unofficial helpers for the Google Discovery V1 API
#
# @api public
#
module DiscoveryV1
  class << self
    # Create a new Google::Apis::DiscoveryV1::DiscoveryService object
    #
    # A credential is not needed to use the DiscoveryService.
    #
    # @example
    #   DiscoveryV1.discovery_service
    #
    # @return [Google::Apis::DiscoveryV1::DiscoveryService] a new DiscoveryService instance
    #
    def discovery_service
      Google::Apis::DiscoveryV1::DiscoveryService.new
    end

    # @!group Validation

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
    # @param rest_description [Google::Apis::DiscoveryV1::RestDescription] the Google Discovery V1 API rest description
    # @param schema_name [String] the name of the schema to validate against
    # @param object [Object] the object to validate
    # @param logger [Logger] the logger to use for logging error, info, and debug message
    #
    # @raise [RuntimeError] if the object does not conform to the schema
    #
    # @return [void]
    #
    def validate_object(rest_description:, schema_name:, object:, logger: Logger.new(nil))
      DiscoveryV1::Validation::ValidateObject.new(rest_description:, logger:).call(schema_name:, object:)
    end

    # List the names of the schemas available to use in the Google Discovery V1 API
    #
    # @example List the name of the schemas available
    #   rest_description = DiscoveryV1.discovery_service.get_rest_api('sheets', 'v4')
    #   DiscoveryV1.api_object_schema_names #=> ["add_banding_request", "add_banding_response", ...]
    #
    # @param rest_description [Google::Apis::DiscoveryV1::RestDescription] the Google Discovery V1 API rest description
    # @param logger [Logger] the logger to use for logging error, info, and debug message
    #
    # @return [Array<String>] the names of the schemas available
    #
    def object_schema_names(rest_description:, logger: Logger.new(nil))
      DiscoveryV1::Validation::LoadSchemas.new(rest_description:, logger:).call.keys.sort
    end

    # @!endgroup
  end
end
