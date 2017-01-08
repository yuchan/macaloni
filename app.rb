require 'twitter'
require 'oauth'
require 'thor'
require 'launchy'

class Macaloni < Thor
	desc 'authorize', 'Authorize Twitter Account.'
	def authorize
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
		puts "Enter the PIN: "
		pin = $stdin.gets.chomp

		access_token = request_token.get_access_token(oauth_verifier: pin)
		oauth_response = access_token.get('/1.1/account/verify_credentials.json?skip_status=true')
	
		client = Twitter::REST::Client.new do |config|
			config.consumer_key        = access_token.consumer.key
			config.consumer_secret     = access_token.consumer.secret
			config.access_token        = access_token.token
			config.access_token_secret = access_token.secret
		end

		client.followers.each do |follower|
			user = client.user(follower.id)
			if user.following? == false
				begin
					created_at = client.user_timeline(follower.id).first.created_at
					three_months_ago = Time.new.utc.to_datetime << 3
					three_years_ago = Time.new.utc.to_datetime << 36
					client.follow(follower.id) if created_at > three_months_ago.to_time
					#client.unfollow(follower.id) if created_at < three_months_ago.to_time
					#p created_at if created_at < three_years_ago.to_time
				rescue Twitter::Error::TooManyRequests
					p "rate limit"
				rescue Twitter::Error::Unauthorized
					p "this account might be private."
				end
			end
		end
	end
end

Macaloni.start(ARGV)