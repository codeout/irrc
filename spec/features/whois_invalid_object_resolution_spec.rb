require 'spec_helper'

describe 'Whois Invalid object resolution' do
  include_context 'whois queries'

  describe 'Try as-jpnic with JPIRR' do
    context 'When invalid object specified' do
      subject {send_query(whois, 'INVALID')}

      it "doesn't report an error" do
        expect(subject['INVALID']).to eq({})
      end
    end

    context 'When a blank String given for IRR object to resolve' do
      subject {send_query(whois, '')}

      it "doesn't report an error" do
        expect(subject['']).to eq({})
      end
    end

    context 'When nil given for IRR object to resolve' do
      subject {send_query(whois, nil)}

      it 'does nothing even reporting the error' do
        expect_any_instance_of(Irrc::Whoisd::Client).not_to receive(:connect)
        expect(subject).to eq({})
      end
    end
  end
end
