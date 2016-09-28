require 'byebug'                # optional, may be helpful
require 'open-uri'              # allows open('http://...') to return body
require 'cgi'                   # for escaping URIs
require 'nokogiri'              # XML parser
require 'active_model'          # for validations

class OracleOfBacon

  class InvalidError < RuntimeError ; end
  class NetworkError < RuntimeError ; end
  class InvalidKeyError < RuntimeError ; end

  attr_accessor :from, :to
  attr_reader :api_key, :response, :uri

  include ActiveModel::Validations
  validates_presence_of :from
  validates_presence_of :to
  validates_presence_of :api_key
  validate :from_does_not_equal_to

  def from_does_not_equal_to
    if @from === @to
      errors.add(:from, "can't be same :to")
    end
  end

  def initialize(api_key='', from = 'Kevin Bacon', to = 'Kevin Bacon')
    @api_key = api_key;
    @from = from
    @to = to
  end

  def find_connections
    make_uri_from_arguments
    begin
      xml = URI.parse(uri).read
    rescue Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, EOFError,
      Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError,
      Net::ProtocolError => e
      # convert all of these into a generic OracleOfBacon::NetworkError,
      #  but keep the original error message
      # your code here
      raise NetworkError.new
    end
      Response.new xml
  end

  def make_uri_from_arguments
    # your code here: set the @uri attribute to properly-escaped URI
    #   constructed from the @from, @to, @api_key arguments
    base = 'http://oracleofbacon.org/cgi-bin/xml'
    @uri = URI.escape "#{base}?a=#{@from}&b=#{@to}&p=#{@api_key}".gsub(/[ #]/, '+')
  end

  class Response
    attr_reader :type, :data
    # create a Response object from a string of XML markup.
    def initialize(xml)
      @doc = Nokogiri::XML(xml)
      parse_response
    end

    private

    def parse_response
      if @doc.xpath('/error').present?
        parse_error_response
      elsif @doc.xpath('/link').present?
        @type = :graph
        @data = @doc.xpath('/link//*').map { |node| node.text }
      elsif @doc.xpath('/spellcheck').present?
        @type = :spellcheck
        @data = @doc.xpath('/spellcheck//match').map { |node| node.text }
      else
        @type = :unknown
        @data = 'unknown response'
      end
    end
    def parse_error_response
      @type = :error
      @data = 'Unauthorized access'
    end
  end
end

