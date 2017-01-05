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

class BugTest < Minitest::Test
  def test_association_stuff
    post = Post.create!

    post.tags << Tag.create!
    post.tags << Tag.create!
    post.tags << Tag.create!
    assert_equal 3, Post.first.tags.count
    assert_equal 3, PostsTag.count
    assert_equal 3, Tag.count
    # should call the create callback
    assert_equal 3, Sign.count
    assert_equal post.id, Tag.first.posts.first.id

    Tag.create!
    post.update tags: Tag.first(4)
    assert_equal 4, Post.first.tags.count
    assert_equal 4, PostsTag.count
    assert_equal 4, Tag.count
    # should call the create callback
    assert_equal 4, Sign.count

    post.tags.destroy(Tag.first)
    assert_equal 3, Post.first.tags.count
    assert_equal 3, PostsTag.count
    assert_equal 5, Sign.count

    # removes last (third) PostsTag
    post.update tag_ids: PostsTag.first(2).pluck(:id)
    assert_equal 2, Post.first.tags.count
    assert_equal 2, PostsTag.count
    #assert_equal 6, Sign.count

    # removes last (second) PostsTag
    post.update tags: [PostsTag.first.tag]
    assert_equal 1, Post.first.tags.count
    assert_equal 1, PostsTag.count
    #assert_equal 7, Sign.count

    last_sign_count = Sign.count
    # add (+1 sign) and remove (+1 sign)
    post.update tag_ids: [Tag.last.id]
    assert_equal 1, Post.first.tags.count
    assert_equal 1, PostsTag.count
    assert_equal last_sign_count + 2, Sign.count

    last_sign_count = Sign.count
    # add (+1 sign) and remove (+1 sign)
    post.update tags: [Tag.first]
    assert_equal 1, Post.first.tags.count
    assert_equal 1, PostsTag.count
    assert_equal last_sign_count + 2, Sign.count
  end
end
