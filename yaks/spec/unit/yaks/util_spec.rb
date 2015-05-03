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

    it 'should resolve a symbol to itself' do
      expect(Resolve(:foo)).to eql :foo
    end

    it 'should resolve custom callables by calling to_proc first' do
      expect(Resolve(fake(to_proc: ->{->{3}}))).to eql 3
    end
  end

  describe '#camelize' do
    it 'should camelize' do
      expect(camelize('foo_bar_moo/baz/booz')).to eql 'FooBarMoo::Baz::Booz'
    end
  end

  describe '#underscore' do
    it 'should underscorize' do
      expect(underscore('FooBar::Baz-Quz::Quux')).to eql 'foo_bar/baz__quz/quux'
    end
  end

  describe '#slice_hash' do
    it 'should retain the given keys from a hash' do
      expect(slice_hash({a: 1, b: 2, c: 3}, :a, :c, :d)).to eql(a: 1, c:3)
    end
  end

  describe '#reject_keys' do
    it 'should reject specific keys from a hash' do
      expect(reject_keys({foo: 1, bar: 2}, :foo)).to eql(bar: 2)
    end
  end

  describe "#symbolize_keys" do
    it "should turn string keys into symbols" do
      expect(symbolize_keys('foo' => 1, 'bar' => 2)).to eql(foo: 1, bar: 2)
    end
  end

  describe '#extract_options' do
    it 'should extract a final hash - one arg given' do
      args, opts = extract_options([:a, {hello: :world}])
      expect([args, opts]).to eql [[:a], {hello: :world}]
    end

    it 'should extract a final hash - multi arg given' do
      args, opts = extract_options([:a, :b, :c, {hello: :world}])
      expect([args, opts]).to eql [[:a, :b, :c], {hello: :world}]
    end

    it 'should provide an empty hash if none was given' do
      args, opts = extract_options([:a, :b])
      expect([args, opts]).to eql [[:a, :b], {}]
    end
  end
end

RSpec.describe Yaks::Util::Deprecated, '#deprecated_alias' do
  let(:klass) {
    Class.new do
      extend Yaks::Util::Deprecated

      def self.to_s ; 'FancyClass' end
      def foo(x); "#{x}yz#{yield}" end
      deprecated_alias :bar, :foo
    end
  }

  def capture_stderr
    stderr, $stderr = $stderr, StringIO.new
    yield
    io, $stderr = $stderr, stderr
    io.string
  end

  it 'should set up an alias' do
    capture_stderr do
      expect(klass.new.bar('x') { 'a' }).to eql 'xyza'
    end
  end

  it 'should output a warning' do
    expect(
      capture_stderr do
        expect(klass.new.bar('x') {'a'}).to eql 'xyza'
      end
    ).to match %r{WARNING: FancyClass#bar is deprecated, use `foo'\. at /.*util_spec.rb:#{__LINE__ - 2}:in}
  end
end
