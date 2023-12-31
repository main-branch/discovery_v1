# frozen_string_literal: true

RSpec.describe DiscoveryV1::Validation::ValidateObject do
  let(:validator) { described_class.new(rest_description:, logger:) }
  let(:rest_description) { double('rest_description', canonical_name: 'sheets_v4', name: 'sheets', version: 'v4') }
  let(:logger) { Logger.new(nil) }

  describe '#initialize' do
    subject { validator }

    it { is_expected.to have_attributes(rest_description:, logger:) }
  end

  describe '#call' do
    subject { validator.call(schema_name:, object:) }

    let(:schemas) do
      {
        'people' => {
          'type' => 'array',
          'items' => { '$ref' => 'person' }
        },
        'person' => {
          'type' => 'object',
          'properties' => {
            'name' => { 'type' => 'string' },
            'location' => { '$ref' => 'location' },
            'active' => { 'type' => 'boolean' }
          },
          'unevaluatedProperties' => false
        },
        'location' => {
          'type' => 'object',
          'properties' => {
            'city' => { 'type' => 'string' },
            'state' => { 'type' => 'string' }
          },
          'unevaluatedProperties' => false
        }
      }
    end

    let(:schemas_loader) { double('schemas_loader') }

    before do
      allow(DiscoveryV1::Validation::LoadSchemas).to(receive(:new).and_return(schemas_loader))
      allow(schemas_loader).to receive(:call).and_return(schemas)
    end

    context 'when the object conforms to the schema' do
      let(:schema_name) { 'location' }

      let(:object) do
        {
          'city' => 'Chicago',
          'state' => 'IL'
        }
      end

      it 'should return true' do
        expect(subject).to eq(true)
      end
    end

    context 'when the object conforms to the schema which contains a ref' do
      let(:schema_name) { 'person' }

      let(:object) do
        {
          'name' => 'James',
          'location' => {
            'city' => 'Chicago',
            'state' => 'IL'
          },
          'active' => true
        }
      end

      it 'should return true' do
        expect(subject).to eq(true)
      end
    end

    context 'when the object conforms to the schema which contains a ref' do
      let(:schema_name) { 'people' }

      let(:object) do
        [
          { 'name' => 'James', 'location' => { 'city' => 'Chicago', 'state' => 'IL' }, 'active' => true },
          { 'name' => 'Jane', 'location' => { 'city' => 'Phoenix', 'state' => 'AZ' }, 'active' => true },
          { 'name' => 'John', 'location' => { 'city' => 'Temecula', 'state' => 'CA' }, 'active' => false }
        ]
      end

      it 'should return true' do
        expect(subject).to eq(true)
      end
    end

    context 'when the object contains an unexpected property' do
      let(:schema_name) { 'location' }

      # contains the unexpected property 'zip'
      let(:object) { { 'city' => 'Chicago', 'state' => 'IL', 'zip' => '60601' } }

      it 'should raise a RuntimeError' do
        expect { subject }.to raise_error(RuntimeError)
      end
    end

    context 'when the object is of the wrong type' do
      let(:schema_name) { 'location' }

      # is an array instead of an object
      let(:object) { [] }

      it 'should raise a RuntimeError' do
        expect { subject }.to raise_error(RuntimeError)
      end
    end

    context 'when an non-exist schema name is given' do
      let(:schema_name) { 'not_found' }

      let(:object) { { 'city' => 'Chicago', 'state' => 'IL' } }

      it 'should raise a RuntimeError' do
        expect { subject }.to raise_error(RuntimeError)
      end
    end
  end
end
