shared_context 'irr queries' do
  let(:irr) { :jpirr }
  let(:irr_fqdn) { 'jpirr.nic.ad.jp' }
  let(:as_set) { 'AS-JPNIC' }
end

shared_context 'whois queries' do
  let(:whois) { :apnic }
  let(:whois_fqdn) { 'whois.apnic.net' }
  let(:as_set) { 'AS-JPNIC' }
end

