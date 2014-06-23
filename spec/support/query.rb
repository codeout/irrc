module QueryHelper
  def send_query(host, object, *options)
    client = Irrc::Client.new(1)
    client.query(host, object, *options)
    client.perform
  end
end
