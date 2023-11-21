# frozen_string_literal: true

require 'uri'

RSpec.describe DiscoveryV1::Validation::ResolveSchemaRef do
  let(:ref_resolver) { described_class.new(rest_description:, logger:) }
  let(:rest_description) { double('rest_description', canonical_name: 'sheets_v4', name: 'sheets', version: 'v4') }
  let(:logger) { Logger.new(nil) }

  let(:schemas) do
    {
      'name' => {
        'type' => 'object',
        'properties' => { 'first' => { 'type' => 'string', 'last' => { 'type' => 'string' } } }
      },
      'person' => {
        'type' => 'object',
        'properties' => { 'name' => { '$ref' => 'name' } }
      }
    }
  end

  describe '#initialize' do
    subject { ref_resolver }

    it { is_expected.to have_attributes(rest_description:, logger:) }
  end

  describe '#call' do
    subject { ref_resolver.call(schema_uri) }

    let(:schemas_loader) { double('schemas_loader') }

    before do
      allow(DiscoveryV1::Validation::LoadSchemas).to(
        receive(:new)
          .with(rest_description:, logger:)
          .and_return(schemas_loader)
      )
      allow(schemas_loader).to receive(:call).and_return(schemas)
    end

    context 'when the schema is found' do
      let(:schema_uri) { URI.parse('json-schemer://schema/person') }
      it { is_expected.to eq(schemas['person']) }
    end

    context 'when the schema is not found' do
      let(:schema_uri) { URI.parse('json-schemer://schema/not_found') }
      it 'should raise a RuntimeError' do
        expect { subject }.to raise_error(RuntimeError)
      end
    end
  end
end
