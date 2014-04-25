unless File.exist?('Gemfile')
  File.write('Gemfile', <<-GEMFILE)
    source 'https://rubygems.org'
    gem 'rails', github: 'rails/rails'
    gem 'sqlite3'
  GEMFILE

  system 'bundle'
end

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

    assert_equal 2, Post.first.tags.count
    assert_equal 2, PostsTag.count
    assert_equal 2, Tag.count
    assert_equal 2, Sign.count
    assert_equal post.id, Tag.first.posts.first.id

    post.tags.destroy(Tag.first)
    assert_equal 1, Post.first.tags.count
    assert_equal 1, PostsTag.count
    assert_equal 3, Sign.count

    post.update tags: []
    assert_equal 0, Post.first.tags.count
    assert_equal 0, PostsTag.count
    assert_equal 4, Sign.count
  end
end
