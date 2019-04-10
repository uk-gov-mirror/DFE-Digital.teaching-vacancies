require 'rails_helper'

RSpec.describe SubscriptionReferenceGenerator do
  describe '.new' do
    it 'should be initialised with a hash of search criteria' do
      service = described_class.new(search_criteria: { 'keyword' => 'Maths', 'radius' => 20 })
      expect(service).to be_an_instance_of(described_class)
    end
  end

  describe '#generate' do
    context 'with no common fields in search criteria' do
      let(:params) { { search_criteria: { 'radius' => 20, 'phase' => 'primary', 'working_pattern' => 'full_time' } } }

      it 'returns nil' do
        service = described_class.new(params)

        expect(service.generate).to eq(nil)
      end
    end

    context 'with keyword in search criteria' do
      let(:params) { { search_criteria: { 'keyword' => 'maths and science', 'radius' => 20 } } }

      it 'returns a reference containing the keyword' do
        service = described_class.new(params)

        expect(service.generate).to include('Maths and science jobs')
      end
    end

    context 'with location in search criteria' do
      let(:params) { { search_criteria: { 'location' => 'London', 'radius' => 40 } } }

      it 'returns a reference containing the keyword' do
        service = described_class.new(params)

        expect(service.generate).to include('within 40 miles of London')
      end
    end
  end
end
