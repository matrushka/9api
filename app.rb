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
	url = "http://9gag.com/hot"
	unless params[:page].nil?
		url += "/#{params[:page]}"
	end
	parse_list_document(url).to_json
end

get '/trending/?:page?' do
	url = "http://9gag.com/trending"
	unless params[:page].nil?
		url += "/#{params[:page]}"
	end
	parse_list_document(url).to_json
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
	url = "http://9gag.com/#{params[:username]}"
	unless params[:page].nil?
		url += "/#{params[:page]}"
	end
	parse_list_document(url).to_json
end

get '/user/:username/likes/?:page?' do
	url = "http://9gag.com/#{params[:username]}/likes"
	unless params[:page].nil?
		url += "/#{params[:page]}"
	end
	parse_list_document(url).to_json
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
		:has_older => (doc.css('#block-content #jump_next:not(.disabled)').length > 0),
		:has_newer => (doc.css('#block-content #jump_prev:not(.disabled)').length > 0),
		:items => items
	}
end

def html_to_obj block
	item = {
		:id => block['gagid'],
		:text => block['data-text'],
		:url => block['data-url'],
		:poster => block.css('.info>h4>a').first.content,
		:loved => block.css('.info>p>span.loved').first.content,
	}

	img = block.css('div.content img').first
	if img.nil?
		# video
		item[:type] = 'video'
	else
		# image
		item[:thumbnail] = img['src']
		item[:full] = img['src'].gsub("_460s.jpg","_700b.jpg")
		item[:type] = 'image'
		item[:is_nsfw] = (img['alt'] == "NSFW")
	end

	return item
end
