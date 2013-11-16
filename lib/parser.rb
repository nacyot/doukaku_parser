Bundler.require(:default)
require 'yaml'

def main
  Dir.glob("./flatten/*").each do |file_name|
    number = file_name.slice(/[0-9]*$/)
    dp = DoukakuParser.new number
    open("./yaml/#{number}.yml", "w+").write(dp.to_yaml)
    puts "#{number} complete!"
  end

  true
end

class DoukakuParser
  attr_reader :post, :url, :comments
  
  def initialize(number)
    @post = Nokogiri::HTML IO.read("./flatten/" + number.to_s)
    @url = "http://ja.doukaku.org/#{number.to_s}"
    @id = number
    @comments = []
    read_comments
  end

  def to_hash
    comments = @comments.map { |comment| comment.to_hash }
    {
      :id => @id,
      :title => title,
      :id => @id,
      :comments => comments
    }
  end

  def to_yaml
    self.to_hash.to_yaml
  end
  
  def title
    @post.css("h2 a")[0].children.to_s
  end

  def read_comments
    @post.css(".comment").each do |comment|
      @comments.push Comment.new(comment, @id)
    end
  end
end

class Comment
  attr_reader :comment
  
  def initialize(comment, parent_id = nil)
    @comment = comment
    @parent_id = parent_id
  end

  def to_hash
    {
      :id => id,
      :parent_id => @parent_id,
      :url => url,
      :user_name => user_name,
      :user_url => user_url,
      :language => language,
      :time => time,
      :vote_count => vote_count,
      :vote_score => vote_score,
      :body => body,
      :code => code,
      :tags => tags,
      :references => references
    }
  end

  def to_yaml
    self.to_hash.to_yaml
  end
  
  def id
    @comment['id'].slice(7, 15)
  end

  def url
    "http://ja.doukaku.org/comment/#{id}"
  end
  
  def user_url
    @comment.css("p.banner>a")[0]['href']
  end

  def user_name
    @comment.css("p.banner>a")[0].children.to_s
  end

  def language
    element = @comment.css("a[href*=lang]")[0]
    return nil unless element
    element.children.to_s.slice(/\w+/) if element
  end
  
  def time
    @comment.css("p.banner script")[0].to_s.slice /(20.*?GMT)/
  end

  def vote_count
    element = @comment.css(".rating span")[0]
    return nil unless element
    element.children.to_s.split(/\/|=/)[1]
  end

  def vote_score
    element = @comment.css(".rating span")[0]
    return nil unless element
    element.children.to_s.split(/\/|=/)[0]
  end

  def body
    @comment.css(".comment_content .comment_body").children.to_s
  end

  def code
    @comment.css("table td.code div.highlight").to_s.gsub(/<\/?(span|div|pre).*?>/, "")
  end

  def code_html
    @comment.css("table").to_s
  end

  def tags
    tags = []
    @comment.css(".addtag ~ a[href*=tag]").each do |tag|
      tags.push tag.children.to_s
    end

    tags
  end

  def references
    @comment.css(".comment_content .link").children.to_s.slice(/href="(.*?)">(.*?)</)
    {url: $1, title: $2}
  end
end
