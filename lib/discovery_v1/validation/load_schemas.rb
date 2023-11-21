# frozen_string_literal: true

require 'active_support'
require 'active_support/inflector'

module DiscoveryV1
  module Validation
    # Load the Google Discovery V1 API description for the Discovery V1 API
    #
    # @example
    #   logger = Logger.new(STDOUT, :level => Logger::ERROR)
    #   schemas = DiscoveryV1::Validation::LoadSchemas.new(logger:).call
    #
    # @api private
    #
    class LoadSchemas
      # Loads schemas for the Discovery V1 API object from the Google Discovery V1 API
      #
      # By default, a nil logger is used. This means that nothing is logged.
      #
      # The schemas are only loaded once and cached.
      #
      # @example
      #   schema_loader = DiscoveryV1::Validation::LoadSchemas.new
      #
      # @param rest_description [Google::Apis::DiscoveryV1::RestDescription]
      #   the api description to load schemas from
      # @param logger [Logger] the logger to use
      #
      def initialize(rest_description:, logger: Logger.new(nil))
        @rest_description = rest_description
        @logger = logger
      end

      # The Google Discovery V1 API description to load schemas from
      #
      # @example
      #   rest_description = DiscoveryV1.discovery_service.get_rest_description('sheets', 'v4')
      #   loader = DiscoveryV1::Validation::LoadSchemas.new(rest_description:)
      #   loader.rest_description == rest_description # => true
      #
      # @return [Google::Apis::DiscoveryV1::RestDescription]
      #
      attr_reader :rest_description

      # The logger to use internally for logging errors
      #
      # @example
      #   logger = Logger.new(STDOUT, :level => Logger::INFO)
      #   schema_loader = DiscoveryV1::Validation::LoadSchemas.new(logger)
      #   schema_loader.logger == logger # => true
      #
      # @return [Logger]
      #
      attr_reader :logger

      # A hash of schemas keyed by schema name loaded from the Google Discovery V1 API
      #
      # @example
      #   DiscoveryV1.api_object_schemas #=> { 'PersonSchema' => { 'type' => 'object', ... } ... }
      #
      # @return [Hash<String, Object>] a hash of schemas keyed by schema name
      #
      def call
        self.class.load_schemas_mutex.synchronize do
          self.class.schemas(rest_description:) ||
            self.class.memoize_schemas(rest_description:, schemas: load_api_schemas)
        end
      end

      private

      # A mutex used to synchronize access to the schemas so they are only loaded
      # once
      #
      # @return [Thread::Mutex]
      #
      @load_schemas_mutex = Thread::Mutex.new

      # Memoization cache that stores the schemas for each rest_description
      #
      # The cache is a hash where:
      # * The key is the canonical name of the rest_description
      # * The value is a hash of schemas keyed by schema name
      #
      # @return [Hash<String, Object] a hash of schemas keyed by schema name
      #
      # @api private
      #
      @schemas_cache = {}

      class << self
        # A mutex used to synchronize access to the schemas so they are only loaded once
        #
        # @return [Thread::Mutex]
        #
        # @api private
        #
        attr_reader :load_schemas_mutex

        # The memoized schemas for the given rest_description or nil
        #
        # @param rest_description [Google::Apis::DiscoveryV1::RestDescription] the
        #   rest_description to get the schemas for
        #
        # @return [Hash<String, Object>, nil] a hash of schemas keyed by schema name
        #
        # @api private
        #
        def schemas(rest_description:)
          @schemas_cache[rest_description.canonical_name]
        end

        # Memoize the schemas for the given rest_description returning the given schemas
        #
        # @param rest_description [Google::Apis::DiscoveryV1::RestDescription] the
        #   rest_description to memoize the schemas for
        # @param schemas [Hash<String, Object>] a hash of schemas keyed by schema name
        #
        # @return [Hash<String, Object>] the given schemas
        #
        # @api private
        #
        def memoize_schemas(rest_description:, schemas:)
          @schemas_cache[rest_description.canonical_name] = schemas
        end

        # Clear the memoization cache (intended for testing)
        #
        # @return [void]
        #
        # @api private
        #
        def clear_schemas_cache
          @schemas_cache = {}
        end
      end

      # Load the schemas from the Google Discovery V1 API
      #
      # @return [Hash<String, Object>] a hash of schemas keyed by schema name
      #
      # @api private
      #
      def load_api_schemas
        source = "https://#{rest_description.name}.googleapis.com/$discovery/rest?version=#{rest_description.version}"
        http_response = Net::HTTP.get_response(URI.parse(source))
        raise_error(http_response) if http_response.code != '200'

        data = http_response.body
        JSON.parse(data)['schemas'].tap { |schemas| post_process_schemas(schemas) }
      end

      # Log an error and raise a RuntimeError based on the HTTP response code
      # @param http_response [Net::HTTPResponse] the HTTP response
      # @return [void]
      # @raise [RuntimeError]
      # @api private
      def raise_error(http_response)
        message = "HTTP Error '#{http_response.code}' loading schemas from '#{http_response.uri}'"
        logger.error(message)
        raise message
      end

      REF_KEY = '$ref'

      # A visitor for the schema object tree that fixes up the tree as it goes
      # @return [void]
      # @api private
      def schema_visitor(path:, object:)
        return unless object.is_a? Hash

        convert_schema_names_to_snake_case(path, object)
        convert_schema_ids_to_snake_case(path, object)
        add_unevaluated_properties(path, object)
        convert_property_names_to_snake_case(path, object)
        convert_ref_values_to_snake_case(path, object)
      end

      # Convert schema names to snake case
      # @return [void]
      # @api private
      def convert_schema_names_to_snake_case(path, object)
        object.transform_keys!(&:underscore) if path.empty?
      end

      # Convert schema IDs to snake case
      # @return [void]
      # @api private
      def convert_schema_ids_to_snake_case(path, object)
        object['id'] = object['id'].underscore if object.key?('id') && path.size == 1
      end

      # Add 'unevaluatedProperties: false' to all schemas
      # @return [void]
      # @api private
      def add_unevaluated_properties(path, object)
        object['unevaluatedProperties'] = false if path.size == 1
      end

      # Convert object property names to snake case
      # @return [void]
      # @api private
      def convert_property_names_to_snake_case(path, object)
        object.transform_keys!(&:underscore) if path[-1] == 'properties'
      end

      # Convert reference values to snake case
      # @return [void]
      # @api private
      def convert_ref_values_to_snake_case(path, object)
        object[REF_KEY] = object[REF_KEY].underscore if object.key?(REF_KEY) && path[-1] != 'properties'
      end

      # Traverse the schema object tree and apply the schema visitor to each node
      # @return [void]
      # @api private
      def post_process_schemas(schemas)
        DiscoveryV1::Validation::TraverseObjectTree.call(
          object: schemas, visitor: ->(path:, object:) { schema_visitor(path:, object:) }
        )
      end
    end
  end
end
