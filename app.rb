require 'twitter'
require 'oauth'
require 'thor'
require 'launchy'
require 'json'

class Macaloni < Thor
  desc "follow_followers", "follow your followers who tweets within the last 3 months."
  def follow_followers
    t.followers.each do |follower|
      user = t.user(follower.id)
      next if user.following?
      begin
        t.follow(follower.id) if active(t, user)
      rescue Twitter::Error::TooManyRequests
        raise
      rescue Twitter::Error::Unauthorized
        p 'this account might be private.'
      end
    end
  end

  desc "unfollow_friends", "unfollow your friends who don't tweets within the last 3 months."
  def unfollow_friends
    t.friends.each do |follower|
      user = t.user(follower.id)
      begin
        t.unfollow(follower.id) unless active(t, user)
      rescue Twitter::Error::TooManyRequests
        raise
      rescue Twitter::Error::Unauthorized
        p 'this account might be private.'
      end
    end
  end

  private

  def t
    content = {}
    begin
      jsonstring = File.read("/tmp/macaloni.json")
      content = JSON.parse(jsonstring)
    rescue
      key        = ENV["TWITTER_CONSUMER_KEY"]
      secret     = ENV["TWITTER_CONSUMER_SECRET"]

      consumer = OAuth::Consumer.new(key, secret, site: Twitter::REST::Client::BASE_URL)      
      request_token = consumer.get_request_token

      request = consumer.create_signed_request(:get, consumer.authorize_path, request_token, {oauth_callback: 'oob'})
      params = request['Authorization'].sub(/^OAuth\s+/, '').split(/,\s+/).collect do |param|
        key, value = param.split('=')
        value =~ /"(.*?)"/
        "#{key}=#{CGI.escape(Regexp.last_match[1])}"
      end.join('&')
      uri = "#{Twitter::REST::Client::BASE_URL}#{request.path}?#{params}"
      Launchy.open(uri)
      puts 'Enter the PIN: '
      pin = $stdin.gets.chomp
      begin
        access_token = request_token.get_access_token(oauth_verifier: pin)
        config = {
          consumer_key:         access_token.consumer.key,
          consumer_secret:      access_token.consumer.secret,
          access_token:         access_token.token,
          access_token_secret:  access_token.secret      
        } 
        content = config.to_json
        File.write("/tmp/macaloni.json", configjson)
      rescue
        raise
      end
    end
    Twitter::REST::Client.new(content)
  end

  def active(cli, user)
    return false if user.statuses_count == 0
    three_months_ago = Time.new.utc.to_datetime << 3
    return false if user.status.created_at < three_months_ago.to_time
    true
  end
end

Macaloni.start(ARGV)
