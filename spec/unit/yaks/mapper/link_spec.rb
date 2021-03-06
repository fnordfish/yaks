require 'spec_helper'

RSpec.describe Yaks::Mapper::Link do
  include_context 'yaks context'

  subject(:link) { described_class.new(rel, template, options) }

  let(:rel)      { :next }
  let(:template) { '/foo/bar/{x}/{y}' }
  let(:options)  { {} }

  its(:template_variables) { should eq [:x, :y] }
  its(:uri_template) { should eq URITemplate.new(template) }

  let(:object) { Struct.new(:x, :y, :returns_nil).new(3, 4, nil) }

  let(:mapper_class) do
    Class.new(Yaks::Mapper) do
      type 'foo'
    end
  end

  let(:mapper) do
    mapper_class.new(yaks_context).tap do |mapper|
      mapper.call(object) # set @object
    end
  end

  describe '#add_to_resource' do
    it 'should add itself to the resource' do
      expect(link.add_to_resource(Yaks::Resource.new, mapper, yaks_context)).to eql(
        Yaks::Resource.new(links: [Yaks::Resource::Link.new(:next, "/foo/bar/3/4", {})])
      )
    end

    context 'with a link function returning nothing' do
      let(:template) { :link_computer }
      before do
        mapper_class.class_eval do
          def link_computer ; end
        end
      end

      it 'should not render the link' do
        expect(link.add_to_resource(Yaks::Resource.new, mapper, yaks_context)).to eql(
          Yaks::Resource.new
        )
      end
    end
  end

  describe '#rel?' do
    it 'should return true if the relation matches' do
      expect(link.rel?(:next)).to be true
    end

    it 'should return false if the relation does not match' do
      expect(link.rel?(:previous)).to be false
    end

    context 'with URI rels' do
      let(:rel) { 'http://foo/bar/rel' }

      it 'should return true if the relation matches' do
        expect(link.rel?('http://foo/bar/rel')).to be true
      end

      it 'should return false if the relation does not match' do
        expect(link.rel?('http://foo/bar/other')).to be false
      end
    end
  end

  describe '#expand_with' do
    it 'should look up expansion values through the provided callable' do
      expect(link.expand_with(->(var){ var.upcase })).to eq '/foo/bar/X/Y'
    end

    context 'with expansion turned off' do
      let(:options) { {expand: false} }

      it 'should keep the template in the response' do
        expect(link.expand_with(->{ })).to eq '/foo/bar/{x}/{y}'
      end
    end

    context 'with a URI without expansion variables' do
      let(:template) { '/orders' }

      it 'should return the link as is' do
        expect(link.expand_with(->{ })).to eq '/orders'
      end
    end

    context 'with partial expansion' do
      let(:options) { { expand: [:y] } }

      it 'should only expand the given variables' do
        expect(link.expand_with({:y => 7}.method(:[]))).to eql '/foo/bar/{x}/7'
      end
    end

    context 'with a symbol for a template' do
      let(:template) { :a_symbol }

      it 'should use the lookup mechanism for finding the link' do
        expect(link.expand_with({:a_symbol => '/foo/foo'}.method(:[]))).to eq '/foo/foo'
      end
    end
  end

  describe '#map_to_resource_link' do
    subject(:resource_link) { link.map_to_resource_link(mapper) }

    its(:rel) { should eq :next }

    context 'with attributes' do
      it 'should not have a title' do
        expect(resource_link.options.key?(:title)).to be false
      end

      it 'should not be templated' do
        expect(resource_link.options[:templated]).to be_falsey
      end

      context 'with extra options' do
        let(:options) { {title: 'foo', expand: [:x], foo: :bar} }

        it 'should pass on unknown options' do
          expect(resource_link.options[:foo]).to eql :bar
        end
      end

      it 'should create an instance of Yaks::Resource::Link' do
        expect(resource_link).to be_a(Yaks::Resource::Link)
      end

      it 'should expand the URI template' do
        expect(resource_link.uri).to eq '/foo/bar/3/4'
      end
    end

    context 'with expansion turned off' do
      let(:options) { {expand: false} }

      it 'should be templated' do
        expect(resource_link.options[:templated]).to be true
      end

      it 'should not propagate :expand' do
        expect(resource_link.options.key?(:expand)).to be false
      end
    end

    context 'with partial expansion' do
      let(:options) { {expand: [:x]} }

      it 'should be templated' do
        expect(resource_link.options[:templated]).to be true
      end
    end

    context 'with a title set' do
      let(:options) { { title: 'link title' } }

      it 'should set the title on the resource link' do
        expect(resource_link.title).to eq 'link title'
      end
    end

    context 'with a title lambda' do
      let(:options) { { title: -> { "say #{mapper_method}" } } }

      before do
        mapper_class.class_eval do
          def mapper_method
            'hello'
          end
        end
      end

      it 'should evaluate the lambda in the context of the mapper' do
        expect(resource_link.title).to eq 'say hello'
      end
    end

    context 'with a link generation method that returns nil' do
      let(:template) { :returns_nil }

      it 'should return nil' do
        expect(resource_link).to be_nil
      end
    end
  end

end
