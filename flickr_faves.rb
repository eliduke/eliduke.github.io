require 'date'
require 'flickr'
require 'open-uri'
require 'bunny_cdn'
require 'dotenv/load'
require 'pry'

# Configures Flickr gem
flickr = Flickr.new(ENV['FLICKR_API_KEY'], ENV['FLICKR_SHARED_SECRET'])

# Authenticates my user for full access to my photos
# Scroll all the way down for more details on that
flickr.access_token = ENV['FLICKR_ACCESS_TOKEN']
flickr.access_secret = ENV['FLICKR_ACCESS_SECRET']

# Configures gem for bunny.net asset uploading
BunnyCdn.configure do |config|
  config.apiKey = ENV['BUNNY_API_KEY']
  config.storageZone = "elidukedotcom"
  config.region = "la"
  config.accessKey = ENV['BUNNY_ACCESS_KEY']
end

photo_ids = ARGV

photo_ids.each do |photo_id|
  info     = flickr.photos.getInfo(photo_id: photo_id)
  sizes    = flickr.photos.getSizes(photo_id: photo_id)
  thumb    = sizes.find { |size| size['label'] == 'Large Square' }['source']
  large    = sizes.find { |size| size['label'] == 'Large 2048' }['source']
  original = sizes.find { |size| size['label'] == 'Original' }['source']

  puts "* Uploading thumbnail image..."
  URI.open(thumb) do |image|
    path = "#{photo_id}-01-thumb.jpg"
    File.open(path, "wb") { |file| file.write(image.read) }
    if BunnyCdn::Storage.uploadFile('faves', path)
      File.delete(path)
    end
  end

  puts "* Uploading large image..."
  URI.open(large) do |image|
    path = "#{photo_id}-02-large.jpg"
    File.open(path, "wb") { |file| file.write(image.read) }
    if BunnyCdn::Storage.uploadFile('faves', path)
      File.delete(path)
    end
  end

  puts "* Uploading original image..."
  URI.open(original) do |image|
    path = "#{photo_id}-03-original.jpg"
    File.open(path, "wb") { |file| file.write(image.read) }
    if BunnyCdn::Storage.uploadFile('faves', path)
      File.delete(path)
    end
  end

  puts "Create fave file..."
  File.open("./_faves/#{photo_id}.md", "wb") do |file|
    file.write(<<~EOS
    ---
    layout: fave
    id: #{photo_id}
    title: >
      #{info['title']}
    description: >
      #{info['description']}
    taken: #{info['dates']['taken']}
    added: #{Time.now}
    photos:
      thumb: https://assets.eliduke.com/faves/#{photo_id}-01-thumb.jpg
      large: https://assets.eliduke.com/faves/#{photo_id}-02-large.jpg
      original: https://assets.eliduke.com/faves/#{photo_id}-03-original.jpg
    ---
    EOS
    )
  end
  puts "Success!! Fave has been saved."
end

# location:
#   locality: #{info['location']['locality']['_content']}
#   region: #{info['location']['region']['_content']}
#   country: #{info['location']['country']['_content']}
#   latitude: #{info['location']['latitude']}
#   longitude: #{info['location']['longitude']}

# This is how I got the Access Token and Access Secret:
#
# token = flickr.get_request_token
# auth_url = flickr.get_authorize_url(token['oauth_token'], :perms => 'delete')
#
# puts "Open this url in your browser to complete the authentication process: #{auth_url}"
# puts "Copy here the number given when you complete the process."
# verify = gets.strip
#
# begin
#   flickr.get_access_token(token['oauth_token'], token['oauth_token_secret'], verify)
#   login = flickr.test.login
#   puts "You are now authenticated as #{login.username} with token #{flickr.access_token} and secret #{flickr.access_secret}"
# rescue Flickr::FailedResponse => e
#   puts "Authentication failed : #{e.msg}"
# end
