# frozen_string_literal: true

RSpec.describe DiscoveryV1::Validation::LoadSchemas do
  let(:schemas_loader) { described_class.new(rest_description:, logger:) }
  let(:rest_description) { sheets_v4_rest_description }
  let(:logger) { Logger.new(nil) }

  let(:sheets_v4_rest_description) do
    double('rest_description', canonical_name: 'sheets_v4', name: 'sheets', version: 'v4')
  end

  let(:sheets_v4_uri) { URI.parse('https://sheets.googleapis.com/$discovery/rest?version=v4') }
  let(:sheets_v4_response) { <<~JSON }
    {
      "kind": "discovery#restDescription",
      "schemas": {
        "GridData": {
          "id": "GridData",
          "type": "object",
          "properties": {
            "rowData": { "type": "array", "items": { "$ref": "RowData" } },
            "startRow": { },
            "startColumn": { }
          }
        },
        "RowData": {
          "id": "RowData",
          "type": "object",
          "properties": {
            "values": { "type": "array", "items": { "$ref": "CellData" } }
          }
        },
        "CellData": {
          "id": "CellData",
          "properties": {
            "userEnteredValue": { "$ref": "ExtendedValue" }
          }
        }
      }
    }
  JSON

  let(:drive_v3_rest_description) do
    double('rest_description', canonical_name: 'drive_v3', name: 'drive', version: 'v3')
  end
  let(:drive_v3_uri) { URI.parse('https://drive.googleapis.com/$discovery/rest?version=v3') }
  let(:drive_v3_response) { <<~JSON }
    {
      "kind": "discovery#restDescription",
      "schemas": {
        "File": {
          "id": "File",
          "type": "object",
          "properties": {
            "name": { "type": "string" }
          }
        }
      }
    }
  JSON

  let(:discovery_v1_rest_description) do
    double('rest_description', canonical_name: 'discovery_v1', name: 'discovery', version: 'v1')
  end
  let(:discovery_v1_uri) { URI.parse('https://discovery.googleapis.com/$discovery/rest?version=v1') }
  let(:discovery_v1_response) { <<~JSON }
    {
      "kind": "discovery#restDescription",
      "schemas": {
        "json_schema": {
          "id": "json_schema",
          "type": "object",
          "properties": {
            "name": { "type": "string" },
            "$ref": { "type": "string" }
          }
        }
      }
    }
  JSON

  describe '#initialize' do
    subject { schemas_loader }

    it { is_expected.to have_attributes(logger:) }
  end

  describe '#call' do
    subject { schemas_loader.call }

    before { described_class.clear_schemas_cache }

    let(:response_code) { '200' }

    before do
      allow(Net::HTTP).to(
        receive(:get_response)
          .with(sheets_v4_uri)
          .and_return(double('response', code: response_code, body: sheets_v4_response, uri: sheets_v4_uri))
      )
      allow(Net::HTTP).to(
        receive(:get_response)
          .with(drive_v3_uri)
          .and_return(double('response', code: response_code, body: drive_v3_response, uri: drive_v3_uri))
      )
      allow(Net::HTTP).to(
        receive(:get_response)
          .with(discovery_v1_uri)
          .and_return(double('response', code: response_code, body: discovery_v1_response, uri: discovery_v1_uri))
      )
    end

    context 'when the HTTP response code is not a "200"' do
      let(:rest_description) { sheets_v4_rest_description }
      let(:response_code) { '500' }

      it 'should raise a RuntimeError' do
        expect { subject }.to raise_error(RuntimeError)
      end
    end

    it 'should return the schemas from the Google Discovery API' do
      expect(subject).to be_a(Hash)
      expect(subject).to have_attributes(size: 3)
    end

    it 'should only request the discovery document once for each API and cache the results' do
      expect(Net::HTTP).to(
        receive(:get_response)
          .with(sheets_v4_uri)
          .once
          .and_return(double('response', body: sheets_v4_response, code: '200', uri: sheets_v4_uri))
      )
      expect(Net::HTTP).to(
        receive(:get_response)
          .with(drive_v3_uri)
          .once
          .and_return(double('response', body: drive_v3_response, code: '200', uri: drive_v3_uri))
      )
      2.times do
        described_class.new(rest_description: sheets_v4_rest_description, logger:).call
        described_class.new(rest_description: drive_v3_rest_description, logger:).call
      end
    end

    it 'should convert schema names to snake case' do
      expect(subject.keys).to eq(%w[grid_data row_data cell_data])
    end

    it 'should convert schema IDs to snake case' do
      expect(subject['grid_data']['id']).to eq('grid_data')
      expect(subject['row_data']['id']).to eq('row_data')
      expect(subject['cell_data']['id']).to eq('cell_data')
    end

    it 'should add "unevaluatedProperties: false" to all schemas' do
      expect(subject['grid_data']['unevaluatedProperties']).to eq(false)
      expect(subject['row_data']['unevaluatedProperties']).to eq(false)
      expect(subject['cell_data']['unevaluatedProperties']).to eq(false)
    end

    it 'should convert object property names to snake case' do
      expect(subject['grid_data']['properties'].keys).to eq(%w[row_data start_row start_column])
      expect(subject['row_data']['properties'].keys).to eq(['values'])
      expect(subject['cell_data']['properties'].keys).to eq(['user_entered_value'])
    end

    it 'should convert reference values to snake case' do
      expect(subject['grid_data']['properties']['row_data']['items']['$ref']).to eq('row_data')
      expect(subject['row_data']['properties']['values']['items']['$ref']).to eq('cell_data')
      expect(subject['cell_data']['properties']['user_entered_value']['$ref']).to eq('extended_value')
    end

    context 'when the schema has a property named "$ref"' do
      let(:rest_description) { discovery_v1_rest_description }

      it 'should allow a property named "$ref"' do
        expect(subject['json_schema']['properties']['$ref']).to eq({ 'type' => 'string' })
      end
    end
  end
end
