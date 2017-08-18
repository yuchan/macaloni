require 'twitter'
require 'launchy'
require 'oauth'
require 'json'

module Macaloni
  module Ext
    module Util
      def t
        Twitter::REST::Client.new(config) unless config.nil?
      end

      def config
        cf = config_from_file
        cf = config_from_oauth if cf.nil?
        File.write("/tmp/macaloni.json", cf.to_json)
        cf
      end

      def config_from_file    
        jsonstring = File.read("/tmp/macaloni.json") if File.exist?("/tmp/macaloni.json")
        config = JSON.parse(jsonstring) unless jsonstring.nil?
      end

      def config_from_oauth
        consumer = OAuth::Consumer.new(ENV["TWITTER_CONSUMER_KEY"], ENV["TWITTER_CONSUMER_SECRET"], site: Twitter::REST::Client::BASE_URL)      
        request_token = consumer.get_request_token

        request = consumer.create_signed_request(:get, consumer.authorize_path, request_token, {oauth_callback: 'oob'})
        params = request['Authorization'].sub(/^OAuth\s+/, '').split(/,\s+/).collect do |param|
          key, value = param.split('=')
          value =~ /"(.*?)"/
          "#{key}=#{CGI.escape(Regexp.last_match[1])}"
        end.join('&')
        uri = "#{Twitter::REST::Client::BASE_URL}#{request.path}?#{params}"
        Launchy.open(uri)
        pin = ask 'Enter the PIN: '
        begin
          access_token = request_token.get_access_token(oauth_verifier: pin)
          config = {
            consumer_key:         access_token.consumer.key,
            consumer_secret:      access_token.consumer.secret,
            access_token:         access_token.token,
            access_token_secret:  access_token.secret      
          }
          config
        rescue
          nil
        end
      end

      def ask(str)
        puts str
        puts '>> '
        $stdin.gets.chomp
      end

      def active(user)
        return false if user.statuses_count.zero?
        three_months_ago = Time.new.utc.to_datetime << 3
        return false if user.status.created_at < three_months_ago.to_time
        true
      end

      def celebrity?(user)
        t.friendship?(user, t.current_user) == false
      end
    end
  end
end
