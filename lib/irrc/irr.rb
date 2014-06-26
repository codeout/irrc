module Irrc
  module Irr
    class << self
      def host(name)
        irr_list[irr_name(name)]
      end

      def irr?(name)
        irr_list.keys.include?(irr_name(name))
      end

      def type(name)
        type_list[irr_name(name)] || type_list[fqdn(name)]
      end

      private

      def irr_list
        @_irr_list ||= Hash[LIST.map {|i| [i[0], i[1]] }]
      end

      def type_list
        @_type_list ||= Hash[LIST.map {|i| [[i[0], i[2]], [i[1], i[2]]] }.flatten(1)]
      end

      def irr_name(name)
        name.to_s.upcase
      end

      def fqdn(fqdn)
        fqdn.to_s.downcase
      end

      # See http://www.irr.net/docs/list.html
      LIST = [
        ['ALTDB',        'whois.altdb.net',         'irrd'],
        ['AOLTW',        'whois.aoltw.net',         'irrd'],
        ['APNIC',        'whois.apnic.net',         'whoisd'],
        ['ARIN',         'rr.arin.net',             'whoisd'],
#        ['BCNET',        'whois.bc.net',            nil],
        ['BELL',         'whois.in.bell.ca',        'irrd'],
        ['BBOI',         'irr.bboi.net',            'irrd'],
        ['CANARIE',      'whois.canarie.ca',        'whoisd'],
        ['D',            'whois.depository.net',    'whoisd'],
#        ['DERU',         'whois.deru.net',          nil],
#        ['DIGITALREALM', 'rr.digitalrealm.net',     nil],
        ['EASYNET',      'whois.noc.easynet.net',   'whoisd'],
#        ['EBIT',         'whois.ebit.ca',           nil],
        ['EPOCH',        'whois.epoch.net',         'irrd'],
        ['GT',           'rr.gt.ca',                'irrd'],
#        ['GW',           'whois.gw.net',            nil],
        ['HOST',         'rr.host.net',             'irrd'],
        ['JPIRR',        'jpirr.nic.ad.jp',         'irrd'],
        ['LEVEL3',       'rr.level3.net',           'whoisd'],
#        ['MTO',          'rr.mtotelecom.com',       nil],
        ['NESTEGG',      'whois.nestegg.net',       'irrd'],
        ['NTTCOM',       'rr.ntt.net',              'irrd'],
        ['OPENFACE',     'whois.openface.ca',       'irrd'],
        ['OTTIX',        'whois.ottix.net',         'irrd'],
        ['PANIX',        'rrdb.access.net',         'irrd'],
        ['RADB',         'whois.radb.net',          'irrd'],
        ['REACH',        'rr.net.reach.com',        'irrd'],
        ['RGNET',        'whois.rg.net',            'irrd'],
        ['RIPE',         'whois.ripe.net',          'whoisd'],
        ['RISQ',         'rr.risq.net',             'irrd'],
        ['ROGERS',       'whois.rogerstelecom.net', 'irrd'],
        ['SAVVIS',       'rr.savvis.net',           'whoisd'],
        ['TC',           'bgp.net.br',              'irrd']
      ]
    end


    def object
      @_object
    end

    def object=(object)
      @_object = object
    end

    # Public: Returns the object type to query.
    # See RFC2622 for details.
    #
    # Returns: A String. ('as-set', 'route-set' or 'aut-num')
    def object_type
      case @_object
      when /^AS-[\w-]+$|:AS-[\w-]+$/i
        'as-set'
      when /^RS-[\w-]+$|:RS-[\w-]+$/i
        'route-set'
      when /^AS\d+$|:AS\d+$/i
        'aut-num'
      end
    end

    def as_set?
      object_type == 'as-set'
    end

    def route_set?
      object_type == 'route-set'
    end

    def aut_num?
      object_type == 'aut-num'
    end
  end
end
