require 'twitter'
require 'thor'
require 'macaloni/ext/util'

module Macaloni
  class Cli < Thor
    include Macaloni::Ext::Util

    desc "follow_followers", "follow your followers who tweets within the last 3 months."
    def follow_followers
      _follow_followers(false)
    end

    desc "follow_followers_with_mute", "follow and mute your followers who tweets within the last 3 months."
    def follow_followers_with_mute
      _follow_followers(true)
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

    desc "mute_friends", "mute friends who follows me."
    def mute_friends
      t.friends.each do |follower|
        user = t.user(follower.id)
        begin
          t.mute(follower.id) if t.friendship?(follower, t.current_user)
        rescue Twitter::Error::TooManyRequests
          raise
        rescue Twitter::Error::Unauthorized
          p 'this account might be private.'
        end
      end      
    end

    desc "unmute_friends", "mute friends who doesn't follows me."
    def unmute_friends
      t.friends.each do |follower|
        user = t.user(follower.id)
        begin
          t.unmute(follower.id) if t.friendship?(follower, t.current_user) == false and follower.muting? == true
        rescue Twitter::Error::TooManyRequests
          raise
        rescue Twitter::Error::Unauthorized
          p 'this account might be private.'
        end
      end      
    end
    
    private

    def _follow_followers(mute)
      t.followers.each do |follower|
        user = t.user(follower.id)
        next if user.following?
        begin
          if active(user)
            t.follow(follower.id)
            t.mute(follower.id) if mute == true
          end
        rescue Twitter::Error::TooManyRequests
          raise
        rescue Twitter::Error::Unauthorized
          p 'this account might be private.'
        end
      end
    end
  end
end