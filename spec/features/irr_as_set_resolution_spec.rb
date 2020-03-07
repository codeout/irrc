require 'spec_helper'

describe 'IRR as-set resolution' do
  include_context 'irr queries'

  context 'When FQDN specified for IRR server' do
    subject {send_query(irr_fqdn, 'AS-JPNIC')}

    it 'returns ipv4 and ipv6 prefixes by default' do
      expect(subject['AS-JPNIC'][:ipv4]['AS2515']).to include '192.41.192.0/24', '202.12.30.0/24',
                                                              '211.120.240.0/21', '211.120.248.0/24'
      expect(subject['AS-JPNIC'][:ipv6]['AS2515']).to include '2001:dc2::/32', '2001:0fa0::/32'
    end
  end

  context 'When a name specified for IRR server' do
    subject {send_query(irr, as_set)}

    it 'returns the same result as if the FQDN specified' do
      expect(subject).to eq send_query(irr_fqdn, as_set)
    end
  end

  it 'gently closes connections to IRR server' do
    expect_any_instance_of(Irrc::Irrd::Client).to receive(:close)
    send_query(irr_fqdn, as_set)
  end

  describe 'Fintering by Authoritative IRR server' do
    subject {send_query(:jpirr, 'AS-JPNIC', source: :apnic)}

    it 'returns nothing' do
      expect(subject).to eq({})
    end
  end

  context 'When as-set resolution is done but something wrong while further processes' do
    subject {send_query(irr, as_set)}
    before do
      allow_any_instance_of(Irrc::Irrd::Client).to receive(:expand_aut_num) {raise}
    end

    it 'ignores a halfway result' do
      expect(subject).to eq({"AS-JPNIC" => {:ipv4 => {"AS2515" => []}, :ipv6 => {"AS2515" => []}}})
    end
  end

  context 'When only ipv4 is specified for protocol' do
    subject {send_query(irr, as_set, protocol: :ipv4)}

    it 'returns nothing about ipv6' do
      expect(subject[as_set][:ipv6]).to be_nil
    end
  end

  context 'When nil specified for protocol' do
    subject {send_query(irr, as_set, protocol: nil)}

    it 'returns nothing about the as-set' do
      expect(subject[as_set]).to eq({})
    end
  end

  context 'When blank protocol specified' do
    subject {send_query(irr, as_set, protocol: [])}

    it 'returns nothing about the as-set' do
      expect(subject[as_set]).to eq({})
    end
  end

  context 'When an invalid protocol specified' do
    subject {send_query(irr, as_set, protocol: :invalid)}

    it 'reports an ArgumentError' do
      expect {subject}.to raise_error ArgumentError
    end
  end

  context 'When a non-mirrored server specified for authoritative IRR server' do
    subject {send_query(irr, as_set, source: :outsider)}

    it 'returns nothing' do
      expect(subject).to eq({})
    end
  end

  context 'When nil specified for authoritative IRR server' do
    subject {send_query(irr, as_set, source: nil)}

    it 'returns a result without any filter of authoritative IRR server' do
      expect(subject).to eq send_query(irr, as_set)
    end
  end

  context 'When blank authoritative IRR server specified' do
    subject {send_query(irr, as_set, source: [])}

    it 'returns a result without any filter of authoritative IRR server' do
      expect(subject).to eq send_query(irr, as_set)
    end
  end

  context 'When non-existent IRR object specified' do
    subject {send_query(irr, 'AS-NON-EXISTENT')}

    it 'ignores the IRR error' do
      expect(subject).to eq({})
    end
  end

  context 'When invalid IRR server name specified' do
    subject {send_query(:invalid, as_set)}

    it 'reports an error' do
      expect {subject}.to raise_error "Unknown type of IRR for 'invalid'."
    end
  end

  context 'When non-resolvable IRR server fqdn specified' do
    subject {send_query('non-resolvable.localdomain', as_set)}

    it 'reports an error' do
      expect {subject}.to raise_error "Unknown type of IRR for 'non-resolvable.localdomain'."
    end
  end

  context 'When unreachable IRR server specified' do
    subject {send_query('192.0.2.1', as_set)}

    it 'reports an error' do
      expect {subject}.to raise_error "Unknown type of IRR for '192.0.2.1'."
    end
  end

  context 'When specifing an IRR server out of service' do
    subject {send_query('127.0.0.1', as_set)}

    it 'reports an error' do
      expect {subject}.to raise_error "Unknown type of IRR for '127.0.0.1'."
    end
  end

  describe 'NOTE: These may fail due to Whois database changes, not code. Check Whois database if fails.' do
    describe 'route-set' do
      subject {send_query(irr, 'RS-RC-26462')}

      it 'returns the same result as Whois database' do
        expect(subject['RS-RC-26462']).to eq(
                                            {:ipv4 => {nil => ["137.238.0.0/16"]}, :ipv6 => {nil => []}}
                                          )
      end
    end

    describe 'nested as-set' do
      subject {send_query(irr, 'AS-TRANSIX-E')}

      it 'returns the same result as Whois database' do
        expect(subject['AS-TRANSIX-E'])
          .to eq({:ipv4=>
                    {"AS173"=>["163.138.160.0/19", "192.47.168.0/23"],
                     "AS2511"=>
                       ["163.138.0.0/17",
                        "192.5.216.0/24",
                        "192.26.94.0/24",
                        "192.47.167.0/24",
                        "163.138.128.0/19"],
                     "AS38644"=>["115.69.232.0/21", "210.173.190.0/24"],
                     "AS4697"=>
                       ["192.47.162.0/23",
                        "192.47.164.0/23",
                        "192.26.93.0/24",
                        "192.172.237.0/24",
                        "192.16.178.0/24"],
                     "AS55391"=>
                       ["217.178.0.0/16",
                        "103.2.249.0/24",
                        "115.69.232.0/22",
                        "115.69.233.0/24",
                        "103.2.250.0/23",
                        "115.69.232.0/23",
                        "14.0.8.0/22",
                        "103.2.251.0/24",
                        "103.2.248.0/22",
                        "103.2.248.0/24",
                        "103.2.250.0/24",
                        "115.69.235.0/24",
                        "115.69.234.0/23",
                        "103.2.248.0/23",
                        "217.178.0.0/18",
                        "115.69.232.0/24",
                        "217.178.128.0/17",
                        "115.69.234.0/24"],
                     "AS55817"=>[],
                     "AS59091"=>["163.138.192.0/19"],
                     "AS7521"=>
                       ["218.100.45.0/24",
                        "210.173.160.0/19",
                        "210.173.160.0/21",
                        "210.173.172.0/24",
                        "210.173.180.0/22",
                        "210.173.184.0/22",
                        "210.173.188.0/23",
                        "210.173.168.0/23",
                        "210.173.170.0/24",
                        "210.173.176.0/24",
                        "210.173.178.0/25"]},
                  :ipv6=>
                    {"AS173"=>[],
                     "AS2511"=>[],
                     "AS38644"=>["2001:03a0:f006::/48"],
                     "AS4697"=>["2001:fa8::/32"],
                     "AS55391"=>["2409:10::/28", "2404:8e00::/32"],
                     "AS55817"=>[],
                     "AS59091"=>[],
                     "AS7521"=>["2001:7fa:7::/48", "2001:3a0::/32"]}}
              )
      end
    end

    describe 'nested route-set' do
      subject {send_query(irr, 'RS-RR-COUDERSPORT')}

      it 'returns the same result as Whois database' do
        expect(subject['RS-RR-COUDERSPORT'])
          .to eq(
                {:ipv4 => {nil => ["107.14.160.0/20", "71.74.32.0/20", "75.180.128.0/19"]},
                 :ipv6 => {nil => []}}
              )
      end
    end
  end
end
