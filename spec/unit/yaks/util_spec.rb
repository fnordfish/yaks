require 'spec_helper'

RSpec.describe Yaks::Util do
  include Yaks::Util

  describe '#Resolve' do
    it 'should return non-proc-values' do
      expect(Resolve('foo')).to eql 'foo'
    end

    it 'should resolve a proc' do
      expect(Resolve(->{ 123 })).to eql 123
    end

    it 'should resolve the proc in the given context' do
      expect(Resolve(->{ upcase }, 'foo')).to eql 'FOO'
    end

    it 'should resolve a proc without context in the context it was lexically defined' do
      expect(Resolve(->{ self })).to be_a RSpec::Core::ExampleGroup
    end

    it 'should receive the context as an argument when it has an arity > 0' do
      expect(Resolve(->(s){ s.upcase }, 'foo')).to eql 'FOO'
    end

    it 'should work with method objects' do
      expect(Resolve('foo'.method(:upcase))).to eql 'FOO'
    end
  end

  describe '#camelize' do
    it 'should camelize' do
      expect(camelize('foo_bar/baz')).to eql 'FooBar::Baz'
    end
  end

  describe '#underscore' do
    it 'should underscorize' do
      expect(underscore('FooBar::Baz-Quz::Quux')).to eql 'foo_bar/baz__quz/quux'
    end
  end
end
