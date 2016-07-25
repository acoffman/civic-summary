class CivicSources < ApiRequest
  private
  def query_string
    'detailed=true'
  end

  def resource
    'sources'
  end
end
