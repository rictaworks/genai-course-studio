require "uri"
module DatabaseSafety
  class Unsafe < StandardError; end
  def self.identity(value)
    uri = URI.parse(value.to_s)
    raise Unsafe unless %w[postgres postgresql].include?(uri.scheme)
    raise Unsafe if uri.host.to_s.empty? || uri.host.include?(",") || uri.path.to_s.length < 2
    options = URI.decode_www_form(uri.query.to_s).to_h
    raise Unsafe unless (options.keys - %w[sslmode connect_timeout application_name]).empty?
    host = uri.host.downcase.delete_suffix(".")
    host = "loopback" if %w[localhost 127.0.0.1 ::1 [::1]].include?(host)
    [ host, uri.port || 5432, URI.decode_www_form_component(uri.path.delete_prefix("/")) ]
  rescue URI::InvalidURIError, ArgumentError
    raise Unsafe
  end
  def self.verify_test!(test_url, development_url)
    test = identity(test_url)
    raise Unsafe if development_url && !development_url.empty? && test == identity(development_url)
    true
  rescue Unsafe
    raise Unsafe, "A separate, valid TEST_DATABASE_URL is required; database tests refused."
  end
end
