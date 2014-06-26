require 'spec_helper'

describe 'IRR as-set resolution' do
  include_context 'irr queries'

  context 'When FQDN specified for IRR server' do
    subject { send_query(irr_fqdn, 'AS-JPNIC') }

    it 'returns ipv4 and ipv6 prefixes by default' do
      expect(subject['AS-JPNIC'][:ipv4]['AS2515']).to include '192.41.192.0/24', '202.12.30.0/24',
      '211.120.240.0/21', '211.120.248.0/24'
      expect(subject['AS-JPNIC'][:ipv6]['AS2515']).to include '2001:dc2::/32', '2001:0fa0::/32'
    end
  end

  context 'When a name specified for IRR server' do
    subject { send_query(irr, as_set) }

    it 'returns the same result as if the FQDN specified' do
      expect(subject).to eq send_query(irr_fqdn, as_set)
    end
  end

  it 'gently closes connections to IRR server' do
    expect_any_instance_of(Irrc::Irrd::Client).to receive(:close)
    send_query(irr_fqdn, as_set)
  end

  describe 'Fintering by Authoritative IRR server' do
    subject { send_query(:jpirr, 'AS-JPNIC', source: :apnic) }

    it 'returns nothing' do
      expect(subject).to eq({})
    end
  end

  context 'When as-set resolution is done but something wrong while further processes' do
    subject { send_query(irr, as_set) }
    before do
      allow_any_instance_of(Irrc::Irrd::Client).to receive(:resolve_prefixes_from_aut_nums){ raise }
    end

    it 'ignores a halfway result' do
      expect(subject).to eq({})
    end
  end

  context 'When only ipv4 is specified for protocol' do
    subject { send_query(irr, as_set, protocol: :ipv4) }

    it 'returns nothing about ipv6' do
      expect(subject[as_set][:ipv6]).to be_nil
    end
  end

  context 'When nil specified for protocol' do
    subject { send_query(irr, as_set, protocol: nil) }

    it 'returns nothing about the as-set' do
      expect(subject[as_set]).to eq({})
    end
  end

  context 'When blank protocol specified' do
    subject { send_query(irr, as_set, protocol: []) }

    it 'returns nothing about the as-set' do
      expect(subject[as_set]).to eq({})
    end
  end

  context 'When an invalid protocol specified' do
    subject { send_query(irr, as_set, protocol: :invalid) }

    it 'reports an ArgumentError' do
      expect { subject }.to raise_error ArgumentError
    end
  end

  context 'When a non-mirrored server specified for authoritative IRR server' do
    subject { send_query(irr, as_set, source: :outsider) }

    it 'returns nothing' do
      expect(subject).to eq({})
    end
  end

  context 'When nil specified for authoritative IRR server' do
    subject { send_query(irr, as_set, source: nil) }

    it 'returns a result without any filter of authoritative IRR server' do
      expect(subject).to eq send_query(irr, as_set)
    end
  end

  context 'When blank authoritative IRR server specified' do
    subject { send_query(irr, as_set, source: []) }

    it 'returns a result without any filter of authoritative IRR server' do
      expect(subject).to eq send_query(irr, as_set)
    end
  end

  context 'When non-existent IRR object specified' do
    subject { send_query(irr, 'AS-NON-EXISTENT') }

    it 'ignores the IRR error' do
      expect(subject).to eq({})
    end
  end

  context 'When invalid IRR server name specified' do
    subject { send_query(:invalid, as_set) }

    it 'reports an error' do
      expect { subject }.to raise_error
    end
  end

  context 'When non-resolvable IRR server fqdn specified' do
    subject { send_query('non-resolvable.localdomain', as_set) }

    it 'reports an error' do
      expect { subject }.to raise_error
    end
  end

  context 'When unreachable IRR server specified' do
    subject { send_query('192.0.2.1', as_set) }

    it 'reports an error' do
      expect { subject }.to raise_error
    end
  end

  context 'When specifing an IRR server out of service' do
    subject { send_query('127.0.0.1', as_set) }

    it 'reports an error' do
      expect { subject }.to raise_error
    end
  end
end
