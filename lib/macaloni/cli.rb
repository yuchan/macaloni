require 'twitter'
require 'thor'
require 'macaloni/ext/util'

module Macaloni
  class Cli < Thor
    include Macaloni::Ext::Util

    desc "follow_followers", "follow your followers who tweets within the last 3 months."
    def follow_followers
      t.followers.each do |follower|
        user = t.user(follower.id)
        next if user.following?
        begin
          t.follow(follower.id) if active(user)
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
          t.unfollow(follower.id) unless active(user)
        rescue Twitter::Error::TooManyRequests
          raise
        rescue Twitter::Error::Unauthorized
          p 'this account might be private.'
        end
      end
    end
  end
end