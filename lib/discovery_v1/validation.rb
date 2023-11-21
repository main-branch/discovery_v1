# frozen_string_literal: true

module DiscoveryV1
  # Validate API Objects against the Google Discovery V1 API
  #
  # @example
  #   discovery_service = DiscoveryV1.discovery_service
  #   rest_description = discovery_service.get_rest_description('sheets', 'v4')
  #   schema_name = 'batch_update_spreadsheet_request'
  #   object = { 'requests' => [] }
  #   DiscoveryV1::Validation::ValidateObject.new(rest_description:).call(schema_name:, object:)
  #
  # @api public
  #
  module Validation; end
end

require_relative 'validation/load_schemas'
require_relative 'validation/resolve_schema_ref'
require_relative 'validation/traverse_object_tree'
require_relative 'validation/validate_object'
