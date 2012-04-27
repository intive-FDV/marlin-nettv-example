require 'rubygems'
require 'sinatra'
require 'sinatra/reloader' if development?
require 'sinatra/config_file'
require 'rest-client'
require 'yaml'

# Load config file.
config_file 'config.yml'

# Reuse the same user credentials for all the requests.
# See comment on `get '/register'`.
USER_ID  = '555556'
USER_KEY = '000102030405060708090a0b0c0d0124'

get '/' do
  erb :content_list, :locals => {:contents => all_contents}
end

get '/download/:content_id' do |content_id|
  set_ce_html_content_type!
  erb :download, :locals => content_info(content_id)
end

get '/stream/:content_id' do |content_id|
  set_ce_html_content_type!
  erb :stream, :locals => content_info(content_id)
end

# Serve a DCF file directly.
get '/contents/:content_id.dcf' do |content_id|
  path = settings.root + '/contents/' + content_id + '.dcf'
  send_file(path)
end

# Acquires a Marlin Broadband Registration action token and serves it directly.
get '/register', :provides => :xml do
  # Here you should use your real user credentials, so this request should be
  # authenticated. The user key should be a 128-bit hex key associated with the
  # user ID. For the purpose of this example, we are using the same credentials
  # for all the requests.
  user_id = USER_ID
  user_key = USER_KEY

  # Make the actual API call to the Hosted Marlin Service.
  RestClient.get hms_api_url, :params => {
      :actionTokenType => '0', # 0 -> Marlin Broadband Registration Token.
      :errorFormat => 'json',
      :customerAuthenticator => settings.customer_authenticator,
      :userId => user_id,
      :userKey => user_key
  }
end

# Acquires a User-Bound Marlin Broadband License transaction token, like a boss.
get '/license/:content_id', :provides => :xml do |content_id|
  content = content_info(content_id)

  RestClient.get hms_api_url, :params => {
      :actionTokenType        => '1', # 1 -> Marlin Broadband License Token.
      :errorFormat            => 'json',
      :customerAuthenticator  => settings.customer_authenticator,
      :userId                 => USER_ID, # See comment about user id above.
      :userKey                => USER_KEY,
      :contentId              => content[:id],
      :contentKey             => content[:key],
      :rightsType             => 'Rental',
      :'rental.periodEndTime' => '+9999', # Use appropriate values here.
      :'rental.playDuration'  => '9999'
  }
end

# Returns a Content Access Descriptor (CAD).
get '/cad/:content_id', :provides => :xml do |content_id|
  erb :cad, :locals => content_info(content_id), :layout => false
end

helpers do
  # Sets the content type of the response to either CE-HTML or XML.
  def set_ce_html_content_type!
    if request.user_agent =~ /Opera\//
      # Opera and NetTV devices recognize CE-HTML mime type.
      content_type 'application/ce-html+xml;charset="UTF-8"'
    else
      # Other browsers don't, but they can render XHTML.
      content_type 'application/xhtml+xml;charset="UTF-8"'
    end
  end

  # Hosted Marlin Service API base URL.
  def hms_api_url
    'https://' + settings.hms_hostname + '/hms/bb/token'
  end

  # Returns a list of all the videos under /contents directory.
  def all_contents
    yml_filenames = Dir.glob(settings.root + '/contents/*.yml')
    yml_filenames.map { |filename|
      id = filename.match(/\/contents\/(.*)\.yml/)[1]
      content_info(id)
    }
  end

  # Returns a hash with the information for a given content ID. The information
  # is taken from the corresponding YAML file under /contents directory.
  def content_info(id)
    filename = settings.root + '/contents/' + id + '.yml'
    content = YAML.load(File.read(filename))

    raise 'Content has not key' unless content[:key]

    # Complete HMS information with default values.
    content[:id]       ||= "urn:marlin:organization:example:#{id}"
    content[:title]    ||= id
    content[:synopsis] ||= content[:title]
    content[:url]      ||= url("/contents/#{id}.dcf")

    # Other useful URLs.
    content[:rights_url]   = url('/license/' + id)
    content[:download_url] = url('/download/' + id)
    content[:stream_url]   = url('/stream/' + id)
    content[:cad_url]   = url('/stream/' + id)

    content
  rescue Errno::ENOENT
    # .yml file does not exist. Show a 404 Not Found.
    not_found
  end
end