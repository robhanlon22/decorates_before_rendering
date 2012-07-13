require_relative '../lib/decorates_before_rendering'

class MyCompletelyFakeModelDecorator; end

describe DecoratesBeforeRendering do
  # NOTE: these are married together, so they're tested together.
  describe '::decorates + #render' do
    let(:sentinel) { double(:sentinel) }
    let(:ivar) { double('@ivar') }

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

        attr_reader :ivar

        def initialize(sentinel, ivar)
          super(sentinel)

          @ivar = ivar
        end
      end
    end
    let(:instance) { klass.new(sentinel, ivar) }
    let(:args) { double('*args') }

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
  end
end
