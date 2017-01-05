#!/usr/bin/env ruby

require 'bundler'

Bundler.setup(:default)

require 'active_record'
require 'minitest/autorun'
require 'logger'

# This connection will do for database-independent bug reports.
ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')
ActiveRecord::Base.logger = Logger.new(STDOUT)

ActiveRecord::Schema.define do
  create_table :posts do |t|
  end

  create_table :posts_tags do |t|
    t.integer :post_id
    t.integer :tag_id
  end

  create_table :tags do |t|
  end

  create_table :signs do |t|
  end
end

class Sign < ActiveRecord::Base
end

class Post < ActiveRecord::Base
  has_many :posts_tags
  has_many :tags, through: :posts_tags
end

class PostsTag < ActiveRecord::Base
  belongs_to :post
  belongs_to :tag

  after_destroy :create_sign
  after_create :create_sign

  private

  def create_sign
    Sign.create
  end
end

class Tag < ActiveRecord::Base
  has_many :posts_tags
  has_many :posts, through: :posts_tags
end

class BugTest < ActiveSupport::TestCase
  def test_association_stuff
    post = Post.create!
    tags = 4.times.map { Tag.create! }

    # add first three tags
    # create callback is fired three times
    assert_difference 'Sign.count', 3 do
      post.tags << tags[0]
      post.tags << tags[1]
      post.tags << tags[2]
    end

    # add the last tag
    # create callback is fired
    assert_difference 'Sign.count', 1 do
      post.update tags: tags
    end

    # remove tags[0]
    # destroy callback is fired
    assert_difference 'Sign.count', 1 do
      post.tags.destroy(tags[0])
    end

    # remove tags[3]
    # destroy callback isn't fired
    assert_difference 'Sign.count', 0 do
    # assert_difference 'Sign.count', 1 do
      post.update tag_ids: [tags[1].id, tags[2].id]
    end

    # removes tags[2]
    # destroy callback isn't fired
    assert_difference 'Sign.count', 0 do
    # assert_difference 'Sign.count', 1 do
      post.update tags: [tags[1]]
    end

    # removes tags[1], adds tags[0]
    # destroy callback isn't fired, create callback is fired
    assert_difference 'Sign.count', 1 do
    # assert_difference 'Sign.count', 2 do
      post.update tag_ids: [tags[0].id]
    end

    # removes tags[0], adds tags[1]
    # destroy callback isn't fired, create callback is fired
    assert_difference 'Sign.count', 1 do
    # assert_difference 'Sign.count', 2 do
      post.update tags: [tags[1]]
    end
  end
end
