require_relative '../lib/decorates_before_rendering'

class MyCompletelyFakeModelDecorator; end
class MyOtherCompletelyFakeModelDecorator; end

describe DecoratesBeforeRendering do
  let(:sentinel) { double(:sentinel) }
  let(:ivar) { double('@ivar') }
  let(:ivars) { double('@ivars') }

  # NOTE: This superclass is here so we know that the correct render gets
  #       called. It can't be defined in the subclass, or else that one
  #       will be the one that's used, as modules sit above their includers
  #       in the class hierarchy.
  let(:superclass) do
    Class.new do
      def initialize(sentinel)
        @sentinel = sentinel
      end

      def render(*args)
        @sentinel.render(*args)
      end
    end
  end
  let(:klass) do
    Class.new(superclass) do
      include DecoratesBeforeRendering

      attr_reader :ivar, :ivars

      def initialize(sentinel, ivar, ivars = nil)
        super(sentinel)

        @ivar = ivar
        @ivars = ivars
      end
    end
  end
  let(:instance) { klass.new(sentinel, ivar, ivars) }
  let(:args) { double('*args') }

  # NOTE: these are married together, so they're tested together.
  describe '::decorates + #render' do
    context "no ivars" do
      it 'should render' do
        sentinel.should_receive(:render).with(args)
        instance.render(args)
      end
    end

    context "ivar is not present" do
      it 'should render' do
        sentinel.should_receive(:render).with(args)
        instance.render(args)
      end
    end

    context "cannot find model name for ivar" do
      it 'should raise an ArgumentError' do
        klass.decorates(:ivar)
        expect {
          instance.render(args)
        }.to raise_error(ArgumentError)
      end
    end

    context "ivar responds to model name" do
      it "should decorate and render" do
        sentinel.should_receive(:render).with(args)
        MyCompletelyFakeModelDecorator.should_receive(:decorate).with(ivar)
        ivar.stub(:model_name => 'MyCompletelyFakeModel')
        klass.decorates(:ivar)
        instance.render(args)
      end
    end

    context "ivar's class responds to model name" do
      it "should decorate and render" do
        sentinel.should_receive(:render).with(args)
        MyCompletelyFakeModelDecorator.should_receive(:decorate).with(ivar)
        ivar.stub_chain(:class, :model_name => 'MyCompletelyFakeModel')
        klass.decorates(:ivar)
        instance.render(args)
      end
    end

    context "subclass inherits attributes" do
      it "should function correctly" do
        klass.decorates(:ivar)
        subclass_instance = Class.new(klass).new(sentinel, ivar)
        sentinel.should_receive(:render).with(args)
        MyCompletelyFakeModelDecorator.should_receive(:decorate).with(ivar)
        ivar.stub_chain(:class, :model_name => 'MyCompletelyFakeModel')
        subclass_instance.render(args)
      end
    end

    context "Specify a different decorator class for an automatic decorator" do
      it "should function correctly" do
        klass.decorates(:ivars, :with => MyOtherCompletelyFakeModelDecorator)
        klass.decorates(:ivar)
        subclass_instance = Class.new(klass).new(sentinel, ivar, ivars)
        sentinel.should_receive(:render).with(args)
        MyOtherCompletelyFakeModelDecorator.should_receive(:decorate).with(ivars)
        MyCompletelyFakeModelDecorator.should_receive(:decorate).with(ivar)
        ivar.stub_chain(:class, :model_name => 'MyCompletelyFakeModel')
        subclass_instance.render(args)
      end
    end
  end

  # for draper >= 1.0
  describe "#decorates_collection + #render" do
    it "requires decorator class (for now)" do
      expect {
        klass.decorates_collection(:ivars)
      }.to raise_error(ArgumentError)
    end

    it "should decorate collection and render" do
      klass.decorates_collection(:ivars, :with => MyCompletelyFakeModelDecorator)
      subclass_instance = Class.new(klass).new(sentinel, ivar, ivars)
      sentinel.should_receive(:render).with(args)
      MyCompletelyFakeModelDecorator.should_receive(:decorate_collection).with(ivars)
      subclass_instance.render(args)
    end
  end
end

