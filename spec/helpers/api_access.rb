require 'rest-client'
require 'api-auth'
require 'json'

require_relative '../../lib/auth'

module ApiAccess
  def new_api_url
    normalize_url("#{URL}/api/v1")
  end

  def old_api_url
    normalize_url(URL.sub('www', 'api'))
  end

  def normalize_url(url)
    url = 'http://' + url unless url.match(%r{\A[a-z][a-z0-9+.-]*://}i)
    url
  end

  def url_collector(url, param={})
    param = param.map do |key, value|
      next if key.to_s.empty? || value.to_s.empty?
      "#{key}=#{URI.encode(value.to_s)}"
    end
    param = param.reject(&:nil?).join('&')
    if param.empty?
      url
    else
      "#{url}#{url.include?('&')?'&':'?'}#{param}"
    end
  end

  def request(param = {})
    request = RestClient::Request.new(self)
    access_id = param.fetch :access_id, Tokens.access_id
    secret_key = param.fetch :secret_token, Tokens.secret_token
    sign = param.fetch :sign, true

    if !sign || access_id.nil? || secret_key.nil?
      request.perform
    else
      ApiAuth.sign!(request, access_id, secret_key).perform
    end
  end

  def perform
    self.execute
  rescue RestClient::ExceptionWithResponse => err
    return err.response
  end

  def parse_body
    JSON.parse(self.body)
  end

  def null
    nil
  end

  class SignOldApi
    class << self
      attr_accessor :token, :cookies, :ttl

      def dont_check_signature(url, param={})
        param.merge!(sheck_signature: 0)
        url_collector(url, param)
      end

      def get_token
        if @token.nil? || @ttl.nil? || @ttl <= Time.now
          res = RestClient.get("#{old_api_url}/hello")
          @ttl = Time.now + res.parse_body['content']['ttl']
          @token = res.parse_body['content']['token']
          @cookies = res.cookies
        end
      end

      def old_api_sign(url, params = {})
        get_token
        str = url
        str << params.
          reject { |key, _| %w(img sign).include?(key.to_s) }.sort.
          map { |key, value| [key.to_s, URI.encode(value.to_s)] }.join
        if str.size > @token.size
          str.insert(@token.size, @token)
        else
          str << @token
        end
        Digest::MD5.hexdigest(str)
      end
    end
  end
end
