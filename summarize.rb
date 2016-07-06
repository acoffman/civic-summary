require 'net/http'
require 'fileutils'
require 'gruff'
require 'json'

class CivicSummaryReport
  attr_reader :api_wrapper, :graph_output_dir

  def initialize(api_wrapper = CivicEvidenceItems, graph_output_dir = 'graphs')
    @api_wrapper = api_wrapper
    @graph_output_dir = graph_output_dir
    FileUtils.mkdir_p(@graph_output_dir)
  end

  def generate!
    data = collect_data
    write_reports(data)
  end

  def collect_data
    counts = Hash.new { |h, k|  h[k] = Hash.new { |ih, ik| ih[ik] = 0 } }

    api_wrapper.new.evidence_items.each do |ei|
      counts['status'][ei['status']] += 1
      next if ei['status'] == 'rejected'

      counts['journals'][extract_journal(ei)] += 1
      counts['articles'][ei['pubmed_id']] += 1
      counts['evidence_types'][ei['evidence_type']] += 1
      counts['evidence_direction'][ei['evidence_direction']] += 1
      counts['rating'][ei['rating']] += 1
      counts['clinical_significances'][ei['clinical_significance']] += 1
      counts['pubmed_ids'][ei['pubmed_id']] += 1
      counts['diseases'][ei['disease']['name']] +=1
      ei['drugs'].each do |drug|
        counts['drugs'][drug['id']] +=1
      end
    end

    counts
  end

  def write_reports(counts)
    puts "Unique pubmed ids: #{counts['pubmed_ids'].keys.size}"
    create_summary_and_plot('Evidence Item Status', counts['status'])
    puts "Unique journals: #{counts['journals'].keys.size}"
    create_summary_and_plot('Evidence Types', counts['evidence_types'])
    create_summary_and_plot('Clinical Significance', counts['clinical_significances'])
    create_summary_and_plot('Evidence Direction', counts['evidence_directions'])
    create_summary_and_plot('Trust Ratings', counts['rating'])
    puts "Unique Drugs #{counts['drugs'].keys.size}"
    puts "Unique Diseases #{counts['diseases'].keys.size}"
  end

  def create_summary_and_plot(title, data)
    g = Gruff::Pie.new
    g.title = title
    puts title
    data.each do |key, count|
      next if key.nil?
      puts "\t#{key.to_s.capitalize}: #{count}"
      g.data(key, count)
    end
    g.write("#{graph_output_dir}/#{title.downcase.gsub(' ', '_')}_chart.png")
  end

  def extract_journal(ei)
    ei['citation'].split(',')[-1]
  end
end

class CivicEvidenceItems
  attr_reader :server

  def initialize(server = 'https://civic.genome.wustl.edu')
    @server = server
  end

  def evidence_items
    initial_url = "#{server}/api/evidence_items"
    page = get_page(initial_url)
    Enumerator.new do |y|
      page.records.each { |v| y << v }
      while url = page.next_page_url
        page = get_page(url)
        page.records.each { |v| y << v }
      end
    end
  end

  private
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

if __FILE__ == $0
  CivicSummaryReport.new.generate!
end
