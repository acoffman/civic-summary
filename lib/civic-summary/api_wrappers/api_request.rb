class ApiRequest
  attr_reader :server

  def initialize(server = 'https://civic.genome.wustl.edu')
    @server = server
    define_singleton_method resource do
      iterate_resources
    end
  end

  private
  def resource
    raise StandardError.new('Define #resource in subclass')
  end

  def query_string
    ''
  end

  def iterate_resources
    initial_url = "#{server}/api/#{resource}?#{query_string}"
    page = get_page(initial_url)
    Enumerator.new do |y|
      page.records.each { |v| y << v }
      while url = page.next_page_url
        page = get_page(url)
        page.records.each { |v| y << v }
      end
    end
  end

  def get_page(url)
    res = Net::HTTP.get_response(URI.parse(url))
    raise StandardError.new("Request Failed!") unless res.code == '200'
    CivicResponse.new(res.body)
  end

  class CivicResponse
    attr_reader :data

    def initialize(body)
      @data = JSON.parse(body)
    end

    def records
      data['records']
    end

    def next_page_url
      data['_meta']['links']['next']
    end
  end

end
