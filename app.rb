# Load gems
require 'rubygems'
require 'bundler'
Bundler.require
require 'open-uri'
require 'logger'

# Setup logger
log_file = "#{File.expand_path(File.dirname(__FILE__))}/log/api.log"
file = File.open(log_file,'a+');
file.sync = true
LOGGER = Logger.new(file)

# Json Content-Type header
before '*' do
	content_type :json
end

get '/' do
	{:name => "9gag api"}.to_json
end

get '/hot/?:page?' do
	params[:page] ||= 1
	parse_list_document("http://9gag.com/hot/#{params[:page]}").to_json
end

get '/trending/?:page?' do
	params[:page] ||= 1
	parse_list_document("http://9gag.com/trending/#{params[:page]}").to_json
end

get '/gag/:id' do

end

get '/user/:username' do
	doc = fetch_url "http://9gag.com/#{params[:username]}"
	{
		:username => params[:username],
		:profile_picture => doc.css('#block-content .profile-image img').first['src'],
		:location => doc.css('#block-content .profile-info>h4').first.content,
		:text => doc.css('#block-content .profile-info>p').first.content
	}.to_json
end

get '/user/:username/posts/?:page?' do
	params[:page] ||= 1
	parse_list_document("http://9gag.com/#{params[:username]}/#{params[:page]}").to_json
end

get '/user/:username/likes/?:page?' do
	params[:page] ||= 1
	parse_list_document("http://9gag.com/#{params[:username]}/likes/#{params[:page]}").to_json
end

def fetch_url url
	LOGGER.info "Fetching: #{url}"
	duration = 0
	begin
		file = open(url)
		status = file.status[0]
		doc = Nokogiri::HTML(file)
		return doc
	rescue OpenURI::HTTPError => error
		status = error.io.status[0]
		return false
	end
end

def parse_list_document url
	items = []
	doc = fetch_url url
	doc.css('#entry-list-ul>li').each do |block|
		items.push(html_to_obj(block))
	end
	{
		:count => items.length,
		:has_next => (doc.css('#block-content #jump_next:not(.disabled)').length > 0),
		:items => items
	}
end

def html_to_obj block
	{
		:id => block['gagid'],
		:text => block['data-text'],
		:url => block['data-url'],
		:thumbnail => block.css('.content a .img-wrap img').first['src'],
		:full => block.css('.content a .img-wrap img').first['src'].gsub("_460s.jpg","_700b.jpg"),
		:poster => block.css('.info>h4>a').first.content,
		:loved => block.css('.info>p>span.loved').first.content,
	}
end
