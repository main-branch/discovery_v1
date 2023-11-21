# frozen_string_literal: true

require 'json_schemer'

module DiscoveryV1
  module Validation
    # Validate objects against a Google Discovery V1 API request object schema
    #
    # @api public
    #
    class ValidateObject
      # Create a new api object validator
      #
      # By default, a nil logger is used. This means that no messages are logged.
      #
      # @example
      #   validator = DiscoveryV1::Validation::ValidateObject.new
      #
      # @param logger [Logger] the logger to use
      #
      def initialize(rest_description:, logger: Logger.new(nil))
        @rest_description = rest_description
        @logger = logger
      end

      # The Google Discovery V1 API description containing schemas to use for validation
      #
      # @example
      #   rest_description = DiscoveryV1.discovery_service.get_rest_description('sheets', 'v4')
      #   validator = DiscoveryV1::Validation::ValidateObject.new(rest_description:)
      #   validator.rest_description == rest_description # => true
      #
      # @return [Google::Apis::DiscoveryV1::RestDescription]
      #
      attr_reader :rest_description

      # The logger to use internally
      #
      # Validation errors are logged at the error level. Other messages are logged
      # at the debug level.
      #
      # @example
      #   logger = Logger.new(STDOUT, :level => Logger::INFO)
      #   validator = DiscoveryV1::Validation::ValidateObject.new(logger)
      #   validator.logger == logger # => true
      #   validator.logger.debug { "Debug message" }
      #
      # @return [Logger]
      #
      attr_reader :logger

      # Validate the object using the JSON schema named schema_name
      #
      # @example
      #   schema_name = 'batch_update_spreadsheet_request'
      #   object = { 'requests' => [] }
      #   validator = DiscoveryV1::Validation::ValidateObject.new
      #   validator.call(schema_name:, object:)
      #
      # @param schema_name [String] the name of the schema to validate against
      # @param object [Object] the object to validate
      #
      # @raise [RuntimeError] if the object does not conform to the schema
      #
      # @return [void]
      #
      def call(schema_name:, object:)
        logger.debug { "Validating #{object} against #{schema_name}" }

        schema = { '$ref' => schema_name }
        schemer = JSONSchemer.schema(schema, ref_resolver:)
        errors = schemer.validate(object)
        raise_error!(schema_name, object, errors) if errors.any?

        logger.debug { "Object #{object} conforms to #{schema_name}" }
      end

      private

      # The resolver to use to resolve JSON schema references
      # @return [ResolveSchemaRef]
      # @api private
      def ref_resolver
        @ref_resolver ||= DiscoveryV1::Validation::ResolveSchemaRef.new(rest_description:, logger:)
      end

      # Raise an error when the object does not conform to the schema
      # @return [void]
      # @raise [RuntimeError]
      # @api private
      def raise_error!(schema_name, _object, errors)
        error = errors.first['error']
        error_message = "Object does not conform to #{schema_name}: #{error}"
        logger.error(error_message)
        raise error_message
      end
    end
  end
end
