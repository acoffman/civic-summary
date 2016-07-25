require 'pry'
require 'pry-nav'

class SourcesReport
  attr_reader :api_wrapper, :graph_output_dir

  def initialize(api_wrapper = CivicSources, graph_output_dir = 'graphs')
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
    api_wrapper.new('http://127.0.0.1:3000/').sources.each do |source|
      counts['journals'][source['journal']] += 1
      source['author_list'].each do |author|
        counts['author_counts'][author] += 1
      end
    end

    counts
  end

  def write_reports(data)
    puts "Unique Journals #{data['journals'].count}"
    puts "Unique Authors #{data['author_counts'].count}"
    authors_sorted_by_paper_count = data['author_counts'].sort_by { |author, count| -count }
      .map { |(author, count)| CivicAuthor.new(author, count) }
      .chunk { |author| author.count }
    max_paper_count = authors_sorted_by_paper_count.first[0]
    max_authors = authors_sorted_by_paper_count.first[1].map { |auth| "\t#{auth.name}" }.join("\n")
    puts "Most papers in CIViC from a single author: #{max_paper_count}"
    puts "Authors with #{max_paper_count} papers in CIViC:"
    puts max_authors
    top_authors = []
    authors_sorted_by_paper_count.each do |_, authors|
      top_authors += authors
      break if top_authors.size > 20
    end

    puts "Top Authors"
    top_authors.each do |auth|
      puts "\t#{auth.name} #{auth.count}"
    end

    generate_author_bar_chart(top_authors)
  end

  def generate_author_bar_chart(authors)
    g = Gruff::SideBar.new('1600x1200')
    g.title = 'Publication count by author'
    g.x_axis_label = 'Publication Count'
    g.y_axis_label = 'Author Name'
    g.minimum_value = 1
    g.maximum_value = authors.first.count
    g.y_axis_increment = 5
    g.marker_font_size = 12
    g.hide_legend = true
    labels = {}
    data = []
    authors.each_with_index do |author, i|
      labels[i] = author.name
      data << author.count
    end
    g.labels = labels
    g.data('Publication Count', data)
    g.write("#{graph_output_dir}/publication_counts_by_authors.png")
  end

  private
  class CivicAuthor
    attr_reader :name, :count
    def initialize(name_hash, count)
      @name = [name_hash['fore_name'], name_hash['last_name']].compact.join(' ')
      @count = count
    end
  end
end
