# frozen_string_literal: true

require 'test_helper'

class MongoidAssociationOwner
  include Mongoid::Document

  has_many :articles, class_name: 'MongoidAssociationArticle', inverse_of: :owner
  has_one :profile, class_name: 'MongoidAssociationProfile', inverse_of: :owner
  has_and_belongs_to_many :tags, class_name: 'MongoidAssociationTag', inverse_of: :owners
  has_many :comments, as: :commentable, class_name: 'MongoidAssociationComment', inverse_of: :commentable
end

class MongoidAssociationArticle
  include Mongoid::Document

  belongs_to :owner, class_name: 'MongoidAssociationOwner', inverse_of: :articles, optional: true
end

class MongoidAssociationProfile
  include Mongoid::Document

  belongs_to :owner, class_name: 'MongoidAssociationOwner', inverse_of: :profile, optional: true
end

class MongoidAssociationTag
  include Mongoid::Document

  has_and_belongs_to_many :owners, class_name: 'MongoidAssociationOwner', inverse_of: :tags
end

class MongoidAssociationComment
  include Mongoid::Document

  belongs_to :commentable, polymorphic: true, inverse_of: :comments, optional: true
end

class MongoidAssociationTest < ActiveSupport::TestCase
  test 'maps real Mongoid reflection classes to association predicates' do
    assert_predicate adapter(MongoidAssociationArticle, :owner), :belongs_to?
    assert_predicate adapter(MongoidAssociationOwner, :profile), :has_one?
    assert_predicate adapter(MongoidAssociationOwner, :articles), :has_many?
    assert_predicate adapter(MongoidAssociationOwner, :tags), :habtm?
    assert_predicate adapter(MongoidAssociationOwner, :articles), :collection?
  end

  test 'exposes real Mongoid reflection metadata' do
    association = adapter(MongoidAssociationArticle, :owner)

    assert_not_predicate association, :polymorphic?
    assert_equal '_id', association.association_primary_key
    assert_nil association.foreign_type
    assert_equal MongoidAssociationArticle, association.inverse_klass
    assert_nil association.as
    assert_nil association.dependent
    assert_equal :articles, association.inverse
    assert_equal '_id', association.quoted_primary_key
  end

  test 'exposes polymorphic reflection metadata' do
    association = adapter(MongoidAssociationComment, :commentable)

    assert_predicate association, :polymorphic?
    assert_not_predicate association, :allow_join?
    assert_equal 'commentable_type', association.foreign_type
  end

  test 'uses the real Mongoid collection name without a running server' do
    assert_equal 'mongoid_association_owners', adapter(MongoidAssociationArticle, :owner).table_name
    assert_equal 'mongoid_association_owners', adapter(MongoidAssociationArticle, :owner).quoted_table_name
  end

  test 'lists real relations from a Mongoid model' do
    associations = described_class.reflect_on_all_associations(MongoidAssociationOwner)

    assert_equal MongoidAssociationOwner.relations.values, associations
    assert_includes associations.map(&:name), :articles
    assert_includes associations.map(&:name), :profile
    assert_includes associations.map(&:name), :tags
  end

  private

  def described_class
    ActiveScaffold::DataStructures::Association::Mongoid
  end

  def adapter(model, name)
    described_class.new(model.relations.fetch(name.to_s))
  end
end
