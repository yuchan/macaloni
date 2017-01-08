require 'twitter'
require 'oauth'
require 'thor'
require 'launchy'

class Macaloni < Thor
  desc "follow_followers", "follow your followers who tweets within the last 3 months."
  def follow_followers
    t = twitter
    t.followers.each do |follower|
      user = t.user(follower.id)
      next if user.following?
      begin
        created_at = t.user_timeline(follower.id).first.created_at
        three_months_ago = Time.new.utc.to_datetime << 3
        three_years_ago = Time.new.utc.to_datetime << 36
        t.follow(follower.id) if created_at > three_months_ago.to_time
        # t.unfollow(follower.id) if created_at < three_months_ago.to_time
        # p created_at if created_at < three_years_ago.to_time
      rescue Twitter::Error::TooManyRequests
        p 'rate limit'
      rescue Twitter::Error::Unauthorized
        p 'this account might be private.'
      end
    end
  end

  desc "unfollow_friends", "unfollow your friends who don't tweets within the last 3 months."
  def unfollow_friends
    t = twitter
    t.friends.each do |follower|
      user = t.user(follower.id)
      begin
        lasttimeline = t.user_timeline(follower.id).first
        if lasttimeline.nil?
          t.unfollow(follower.id)
        else
          created_at = t.user_timeline(follower.id).first.created_at
          three_months_ago = Time.new.utc.to_datetime << 3
          three_years_ago = Time.new.utc.to_datetime << 36
          t.unfollow(follower.id) if created_at < three_months_ago.to_time
        end
      rescue Twitter::Error::TooManyRequests
        p 'rate limit'
      rescue Twitter::Error::Unauthorized
        p 'this account might be private.'
      end
    end
  end

  private

  def twitter
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

    access_token = request_token.get_access_token(oauth_verifier: pin)
    oauth_response = access_token.get('/1.1/account/verify_credentials.json?skip_status=true')

    cli = Twitter::REST::Client.new do |config|
      config.consumer_key        = access_token.consumer.key
      config.consumer_secret     = access_token.consumer.secret
      config.access_token        = access_token.token
      config.access_token_secret = access_token.secret
    end
    cli
  end
end

Macaloni.start(ARGV)
