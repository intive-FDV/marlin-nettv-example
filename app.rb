require 'rubygems'
require 'sinatra'
require 'sinatra/reloader' if development?
require 'sinatra/config_file'
require 'rest-client'
require 'yaml'

# Load config file.
config_file 'config.yml'

# Reuse the same user credentials for all the requests.
USER_ID = '555556'
USER_KEY = '000102030405060708090a0b0c0d0124'

get '/' do

end

get '/download/:content_id' do |content_id|
  set_ce_html_content_type!
  erb :download, :locals => {:cad_url => url('/cad/' + content_id)}
end

get '/stream/:content_id' do |content_id|
  set_ce_html_content_type!
  erb :stream, :locals => {:cad_url => url('/cad/' + content_id)}
end

get '/contents/:content_id.dcf' do |content_id|
  path = settings.root + '/contents/' + content_id + '.dcf'
  send_file(path)
end

get '/register', :provides => :xml do
  # Here you should use the user id of your application, associated with the
  # user that made the request. The user key should be a 128-bit hex key
  # associated with that id. For the purpose of this example, we are using the
  # same credentials for all the requests.
  user_id = USER_ID
  user_key = USER_KEY

  RestClient.get hms_token_api_url, :params => {
      :actionTokenType => '0', # 0 -> Marlin Broadband Registration Token.
      :errorFormat => 'json',
      :customerAuthenticator => settings.customer_authenticator,
      :userId => user_id,
      :userKey => user_key
  }
end

get '/license/:content_id', :provides => :xml do |content_id|

  content = content_info(content_id)

  RestClient.get hms_token_api_url, :params => {
      :actionTokenType => '1', # 1 -> Marlin Broadband License Token.
      :errorFormat => 'json',
      :customerAuthenticator => settings.customer_authenticator,
      :userId => USER_ID, # See comment about user id above.
      :userKey => USER_KEY,
      :contentId => content[:content_id],
      :contentKey => content[:content_key],
      :rightsType => 'Rental',
      :'rental.periodEndTime' => '+9999',
      :'rental.playDuration' => '9999'
  }
end

get '/cad/:content_id', :provides => :xml do |content_id|
  erb :cad, :locals => content_info(content_id), :layout => false
end

helpers do
  def set_ce_html_content_type!
    if request.user_agent =~ /Opera\//
      # Opera and NetTV devices recognize CE-HTML mime type.
      content_type 'application/ce-html+xml;charset="UTF-8"'
    else
      # Other browsers don't, but they can render XHTML.
      content_type 'application/xhtml+xml;charset="UTF-8"'
    end
  end

  def hms_token_api_url
    'https://' + settings.hms_hostname + '/hms/bb/token'
  end

  def content_info(content_id)
    #path = settings.root + '/contents/' + content_id + '.yml'
    #content = YAML.load(File.read(path))
    {
        :content_id => "urn:marlin:organization:fdvs:#{content_id}",
        :content_key => '000102030405060708090a0b0c0d0e0f',
        :title => "Title #{content_id}",
        :synopsis => "Synopsis #{content_id}",
        :origin_site => base_url,
        :origin_site_name => 'Marlin NetTV Example',
        :content_url => "#{base_url}/contents/#{content_id}.dcf",
        :artwork_url => 'http://laughingsquid.com/wp-content/uploads/nyan.jpg',
        :rights_url => "#{base_url}/license/#{content_id}"
    }
  end

  def base_url
    "#{request.env['rack.url_scheme']}://#{request.env['HTTP_HOST']}"
  end
end