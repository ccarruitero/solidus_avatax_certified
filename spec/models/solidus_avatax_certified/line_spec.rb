# frozen_string_literal: true

require 'spec_helper'

describe SolidusAvataxCertified::Line, :vcr do
  let!(:order) { create(:avalara_order, line_items_count: 2) }
  let(:sales_lines) { SolidusAvataxCertified::Line.new(order, 'SalesOrder') }

  describe '#initialize' do
    it 'has order' do
      expect(sales_lines.order).to eq(order)
    end
    it 'has lines be an array' do
      expect(sales_lines.lines).to be_kind_of(Array)
    end
    it 'lines should be a length of 3' do
      expect(sales_lines.lines.length).to eq(3)
    end
  end

  context 'sales order' do
    describe '#build_lines' do
      it 'receives method item_lines_array' do
        expect(sales_lines).to receive(:item_lines_array)
        sales_lines.build_lines
      end
      it 'receives method shipment_lines_array' do
        expect(sales_lines).to receive(:shipment_lines_array)
        sales_lines.build_lines
      end
    end

    describe '#item_lines_array' do
      it 'returns an Array' do
        expect(sales_lines.item_lines_array).to be_kind_of(Array)
      end
    end

    describe '#shipment_lines_array' do
      it 'returns an Array' do
        expect(sales_lines.shipment_lines_array).to be_kind_of(Array)
      end
      it 'has a length of 1' do
        expect(sales_lines.shipment_lines_array.length).to eq(1)
      end
    end

    describe '#item_line' do
      it 'returns a Hash with correct keys' do
        expect(sales_lines.item_line(order.line_items.first))
          .to be_kind_of(Hash)
        expect(sales_lines.item_line(order.line_items.first)[:number])
          .to be_present
      end
    end

    describe '#shipment_line' do
      it 'returns a Hash with correct keys' do
        expect(sales_lines.shipment_line(order.shipments.first))
          .to be_kind_of(Hash)
        expect(sales_lines.shipment_line(order.shipments.first)[:number])
          .to be_present
      end
    end
  end

  context 'return invoice' do
    let(:authorization) { generate(:refund_transaction_id) }
    let(:payment_amount) { 10 * 2 }
    let(:payment_method) { build(:credit_card_payment_method) }
    let(:payment) do
      build(
        :payment,
        amount: payment_amount,
        payment_method: payment_method,
        order: order
      )
    end
    let!(:refund_reason) { create(:refund_reason) }
    let(:gateway_response) {
      ActiveMerchant::Billing::Response.new(
        gateway_response_success,
        gateway_response_message,
        gateway_response_params,
        gateway_response_options
      )
    }
    let(:gateway_response_success) { true }
    let(:gateway_response_message) { '' }
    let(:gateway_response_params) { {} }
    let(:gateway_response_options) { {} }
    let!(:refund) do
      Spree::Refund.new(
        payment: payment,
        amount: BigDecimal(10),
        reason: refund_reason,
        transaction_id: nil
      )
    end
    let!(:shipped_order) { create(:shipped_order) }
    let(:return_lines) do
      SolidusAvataxCertified::Line.new(shipped_order, 'ReturnOrder', refund)
    end

    describe 'build_lines' do
      it 'receives method refund_lines' do
        expect(return_lines).to receive(:refund_lines)
        return_lines.build_lines
      end
    end

    describe '#refund_line' do
      it 'returns an Hash' do
        expect(return_lines.refund_line).to be_kind_of(Hash)
      end
    end

    describe '#refund_line' do
      it 'returns an Array' do
        expect(return_lines.refund_lines).to be_kind_of(Array)
      end
    end
  end
end
