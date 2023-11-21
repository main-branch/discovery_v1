# frozen_string_literal: true

RSpec.describe DiscoveryV1 do
  it 'has a version number' do
    expect(DiscoveryV1::VERSION).not_to be nil
  end

  describe '.discovery_service' do
    subject(:discovery_service) { described_class.discovery_service }

    it 'returns a Google::Apis::DiscoveryV1::DiscoveryService' do
      expect(discovery_service).to be_a(Google::Apis::DiscoveryV1::DiscoveryService)
    end
  end

  describe '.validate_object' do
    subject { described_class.validate_object(rest_description:, schema_name:, object:, logger:) }
    let(:rest_description) { double('rest_description') }
    let(:schema_name) { double('schema_name') }
    let(:object) { double('object') }
    let(:logger) { double('logger') }

    it 'should call DiscoveryV1::Validation::ValidateObject to do the validation' do
      expect(DiscoveryV1::Validation::ValidateObject).to(
        receive(:new)
        .with(rest_description:, logger:)
        .and_call_original
      )
      expect_any_instance_of(DiscoveryV1::Validation::ValidateObject).to(
        receive(:call)
        .with(schema_name:, object:)
      )
      subject
    end
  end

  describe '.object_schema_names' do
    subject { described_class.object_schema_names(rest_description:, logger:) }
    let(:rest_description) { double('rest_description') }
    let(:logger) { double('logger') }
    let(:schema_loader) { double('schema_loader') }
    let(:schemas) { double('schemas') }
    let(:schema_names) { %w[schema1 schema2] }
    let(:expected_result) { double('expected_result') }

    before do
      allow(DiscoveryV1::Validation::LoadSchemas).to(
        receive(:new)
        .with(rest_description:, logger:)
        .and_return(schema_loader)
      )
      allow(schema_loader).to receive(:call).and_return(schemas)
      allow(schemas).to receive(:keys).and_return(schema_names)
    end

    it 'should call DiscoveryV1::ApiObjectValidation::LoadSchemas to load the schemas' do
      expect(subject).to eq(schema_names)
    end
  end
end
