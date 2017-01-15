require 'spec_helper'

describe 'Whois as-set resolution' do
  include_context 'whois queries'

  context 'When FQDN specified for Whois server' do
    subject { send_query(whois_fqdn, 'AS-JPNIC') }

    it 'returns ipv4 and ipv6 prefixes by default' do
      expect(subject['AS-JPNIC'][:ipv4]['AS2515']).to include '192.41.192.0/24', '202.12.30.0/24',
      '211.120.240.0/21', '211.120.248.0/24'
      expect(subject['AS-JPNIC'][:ipv6]['AS2515']).to include '2001:dc2::/32', '2001:0fa0::/32'
    end
  end

  context 'When a name specified for Whois server' do
    subject { send_query(whois, as_set) }

    it 'returns the same result as if the FQDN specified' do
      expect(subject).to eq send_query(whois_fqdn, as_set)
    end
  end

  it 'gently closes connections to Whois server' do
    expect_any_instance_of(Irrc::Whoisd::Client).to receive(:close)
    send_query(whois_fqdn, as_set)
  end

  describe 'Fintering by Authoritative Whois server' do
    subject { send_query(:jpirr, 'AS-JPNIC', source: :apnic) }

    it 'returns nothing' do
      expect(subject).to eq({})
    end
  end

  context 'When as-set resolution is done but something wrong while further processes' do
    subject { send_query(whois, as_set) }
    before do
      allow_any_instance_of(Irrc::Whoisd::Client).to receive(:expand_aut_num){ raise }
    end

    it 'ignores a halfway result' do
      expect(subject).to eq({"AS-JPNIC"=>{:ipv4=>{"AS2515"=>[]}, :ipv6=>{"AS2515"=>[]}}})
    end
  end

  context 'When only ipv4 is specified for protocol' do
    subject { send_query(whois, as_set, protocol: :ipv4) }

    it 'returns nothing about ipv6' do
      expect(subject[as_set][:ipv6]).to be_nil
    end
  end

  context 'When nil specified for protocol' do
    subject { send_query(whois, as_set, protocol: nil) }

    it 'returns nothing about the as-set' do
      expect(subject[as_set]).to eq({})
    end
  end

  context 'When blank protocol specified' do
    subject { send_query(whois, as_set, protocol: []) }

    it 'returns nothing about the as-set' do
      expect(subject[as_set]).to eq({})
    end
  end

  context 'When an invalid protocol specified' do
    subject { send_query(whois, as_set, protocol: :invalid) }

    it 'reports an ArgumentError' do
      expect { subject }.to raise_error ArgumentError
    end
  end

  context 'When a non-mirrored server specified for authoritative Whois server' do
    subject { send_query(whois, as_set, source: :outsider) }

    it 'returns nothing' do
      expect(subject).to eq({})
    end
  end

  context 'When nil specified for authoritative Whois server' do
    subject { send_query(whois, as_set, source: nil) }

    it 'returns a result without any filter of authoritative Whois server' do
      expect(subject).to eq send_query(whois, as_set)
    end
  end

  context 'When blank authoritative Whois server specified' do
    subject { send_query(whois, as_set, source: []) }

    it 'returns a result without any filter of authoritative Whois server' do
      expect(subject).to eq send_query(whois, as_set)
    end
  end

  context 'When non-existent Whois object specified' do
    subject { send_query(whois, 'AS-NON-EXISTENT') }

    it 'ignores the Whois error' do
      expect(subject).to eq({})
    end
  end

  context 'When as-sets cross-refers to each other' do
    before do
      allow_any_instance_of(Irrc::Whoisd::Client).to receive(:execute) {|client, command|
        case command
        when /AS-A/
          "members:        AS1\nmembers:        AS-B"
        when /AS-B/
          "members:        AS-A"
        when /AS1/
          "route:          192.0.2.0/24"
        end
      }
    end
    let(:looped_as_set) { 'AS-A' }

    subject { send_query(whois, looped_as_set) }

    it 'breaks out of the loop and returns something' do
      expect(subject['AS-A']).to eq(
        {:ipv4=>{"AS1"=>["192.0.2.0/24"]}, :ipv6=>{"AS1"=>[]}}
      )
    end
  end

  context 'When route-sets cross-refers to each other' do
    before do
      allow_any_instance_of(Irrc::Whoisd::Client).to receive(:execute) {|client, command|
        case command
        when /RS-A/
          "members:        192.0.2.0/24\nmembers:        RS-B"
        when /RS-B/
          "members:        RS-A"
        end
      }
    end
    let(:looped_route_set) { 'RS-A' }

    subject { send_query(whois, looped_route_set) }

    it 'breaks out of the loop and returns something' do
      expect(subject['RS-A']).to eq(
        {:ipv4=>{nil=>["192.0.2.0/24"]}, :ipv6=>{nil=>[]}}
      )
    end
  end

  context 'When invalid Whois server name specified' do
    subject { send_query(:invalid, as_set) }

    it 'reports an error' do
      expect { subject }.to raise_error "Unknown type of IRR for 'invalid'."
    end
  end

  context 'When non-resolvable Whois server fqdn specified' do
    subject { send_query('non-resolvable.localdomain', as_set) }

    it 'reports an error' do
      expect { subject }.to raise_error "Unknown type of IRR for 'non-resolvable.localdomain'."
    end
  end

  context 'When unreachable Whois server specified' do
    subject { send_query('192.0.2.1', as_set) }

    it 'reports an error' do
      expect { subject }.to raise_error "Unknown type of IRR for '192.0.2.1'."
    end
  end

  context 'When specifing an Whois server out of service' do
    subject { send_query('127.0.0.1', as_set) }

    it 'reports an error' do
      expect { subject }.to raise_error "Unknown type of IRR for '127.0.0.1'."
    end
  end

  describe 'NOTE: These may fail due to Whois database changes, not code. Check Whois database if fails.' do
    describe 'route-set' do
      subject { send_query(whois, 'RS-RC-26462') }

      it 'returns the same result as Whois database' do
        expect(subject['RS-RC-26462']).to eq(
          {:ipv4=>{nil=>["137.238.0.0/16"]}, :ipv6=>{nil=>["2620:0:5080::/48"]}}
        )
      end
    end

    describe 'nested as-set' do
      subject { send_query(whois, 'AS-PDOXUPLINKS', source: :apnic) }

      it 'returns the same result as Whois database' do
        expect(subject['AS-PDOXUPLINKS']).to eq(
          {:ipv4=>
             {"AS703"=>[],
              "AS1221"=>["203.92.26.0/24"],
              "AS2764"=>["103.62.28.0/23"],
              "AS7474"=>[],
              "AS7657"=>[],
              "AS4565"=>[],
              "AS5650"=>[],
              "AS6461"=>[]},
           :ipv6=>
             {"AS703"=>[],
              "AS1221"=>[],
              "AS2764"=>[],
              "AS7474"=>[],
              "AS7657"=>[],
              "AS4565"=>[],
              "AS5650"=>[],
              "AS6461"=>[]}}
        )
      end
    end

    describe 'nested route-set' do
      subject { send_query(whois, 'RS-RR-COUDERSPORT') }

      it 'returns the same result as Whois database' do
        expect(subject['RS-RR-COUDERSPORT']).to eq(
          {:ipv4=>{nil=>["71.74.32.0/20", "75.180.128.0/19", "107.14.160.0/20"]},
           :ipv6=>{nil=>[]}}
        )
      end
    end
  end
end
