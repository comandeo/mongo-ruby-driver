require 'opentelemetry/sdk'
require 'lite_spec_helper'

RSpec.describe Mongo::Monitoring::OpenTelemetry::Tracer do
  let(:tracer) { described_class.new }

  describe '#initialize' do
    context 'when not enabled' do
      before do
        allow(ENV).to receive(:[]).with(described_class::ENV_VARIABLE_ENABLED).and_return(nil)
      end

      it 'does not create a tracer' do
        expect(tracer.ot_tracer).to be_nil
      end
    end
  end

  describe '#in_span' do
    context 'when disabled' do
      before do
        allow(ENV).to receive(:[]).with(described_class::ENV_VARIABLE_ENABLED).and_return(nil)
      end

      it 'yields to the block' do
        expect { |b| tracer.in_span(nil, nil, nil, &b) }.to yield_control
      end
    end

    context 'when enabled' do
      before do
        allow(ENV).to receive(:[]).with(described_class::ENV_VARIABLE_ENABLED).and_return('true')
      end
    end
  end
end
