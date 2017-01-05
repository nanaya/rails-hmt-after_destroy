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

  create_table :create_signs do |t|
  end

  create_table :destroy_signs do |t|
  end
end

class CreateSign < ActiveRecord::Base
end

class DestroySign < ActiveRecord::Base
end

class Post < ActiveRecord::Base
  has_many :posts_tags
  has_many :tags, through: :posts_tags
end

class PostsTag < ActiveRecord::Base
  belongs_to :post
  belongs_to :tag

  after_destroy :create_destroy_sign
  after_create :create_create_sign

  private

  def create_create_sign
    CreateSign.create
  end

  def create_destroy_sign
    DestroySign.create
  end
end

class Tag < ActiveRecord::Base
  has_many :posts_tags
  has_many :posts, through: :posts_tags
end

class BugTest < ActiveSupport::TestCase
  setup do
    @post = Post.create!
  end

  test "adding tags using <<" do
    assert_difference 'CreateSign.count', 1 do
      @post.tags << Tag.create!
    end
  end

  test "adding tags using assignment" do
    assert_difference 'CreateSign.count', 1 do
      @post.update tags: [Tag.create!]
    end
  end

  test "adding tags using tag_ids assignment" do
    assert_difference 'CreateSign.count', 1 do
      @post.update tag_ids: [Tag.create!.id]
    end
  end

  test "removing tags using tags.destroy" do
    tags = 2.times.map { Tag.create! }
    @post.update tags: tags

    assert_difference 'DestroySign.count', 1 do
      @post.tags.destroy(tags[0])
    end
  end

  test "removing tags using tag_ids assignment" do
    tags = 2.times.map { Tag.create! }
    @post.update tags: tags

    assert_difference 'DestroySign.count', 1 do
      @post.update tag_ids: [tags[0].id]
    end
  end

  test "removing tags using tags assignment" do
    tags = 2.times.map { Tag.create! }
    @post.update tags: tags

    assert_difference 'DestroySign.count', 1 do
      @post.update tags: [tags[0]]
    end
  end

  test "removing and adding tags using tags assignment" do
    tags = 2.times.map { Tag.create! }
    @post.update tags: [tags[0]]

    assert_difference ['CreateSign.count', 'DestroySign.count'], 1 do
      @post.update tags: [tags[1]]
    end
  end

  test "removing and adding tags using tag_ids assignment" do
    tags = 2.times.map { Tag.create! }
    @post.update tags: [tags[0]]

    assert_difference ['CreateSign.count', 'DestroySign.count'], 1 do
      @post.update tag_ids: [tags[1].id]
    end
  end
end
