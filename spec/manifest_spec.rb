require File.dirname(__FILE__) + '/spec_helper.rb'

describe "A manifest" do

  describe "when blank" do

    before(:each) do
      @manifest = BlankManifest.new
    end

    it "does nothing" do
      @manifest.class.recipes.should == []
    end

    it "returns true when executed" do
      @manifest.execute.should be_true
    end

  end

  describe "without specified recipes" do

    before(:each) do
      @manifest = NoOpManifest.new
    end

    it "is executable by default" do
      @manifest.should be_executable
    end

    describe "when calling instance methods" do

      before(:each) do
        @manifest.foo
      end

      it "creates resources" do
        @manifest.execs.keys.sort.should == ['foo']
      end

      it "applies our customizations to resources" do
        @manifest.execs["foo"].path.should == ENV["PATH"]
      end

      describe "and then executing" do

        before(:each) do
          @manifest = @manifest.execute
        end

        it "returns true" do
          @manifest.should be_true
        end

      end

    end

  end

  describe "when recipes aren't fullfilled" do

    before(:each) do
      @manifest = RequirementsNotMet.new
    end

    it "returns false when executed" do
      @manifest.execute.should be_false
    end

    it "raises an error when executed!" do
      lambda {
        @manifest.execute!
      }.should raise_error(NameError)
    end

  end

  describe "in general" do

    before(:each) do
      @manifest = RequiresMetViaMethods.new
    end

    it "knows what it's supposed to do" do
      @manifest.class.recipes.should == [[:foo, {}], [:bar, {}]]
    end

    it "loading configuration on the class" do
      @manifest.class.configuration[:foo].should == :bar
    end

    it "can access the same configuration hash on the instance" do
      @manifest.configuration[:foo].should == :bar
    end

    it "has a name" do
      @manifest.name.should == "#{@manifest.class}##{@manifest.object_id}"
    end

    describe 'when evaluated' do

      it "calls specified methods" do
        @manifest.should_receive(:foo)
        @manifest.should_receive(:bar)
        @manifest.send(:evaluate_recipes)
      end

      it "passes the configuration hash key named by each method if no options given" do
        @manifest = ConfigurationWithConvention.new
        @manifest.should_receive(:foo).with(:bar).exactly(1).times
        @manifest.send(:evaluate_recipes)
      end

      it "creates new resources" do
        @manifest.should_receive(:new_resource).with(Puppet::Type::Exec, 'foo', :command => 'true').exactly(1).times
        @manifest.should_receive(:new_resource).with(Puppet::Type::Exec, 'bar', :command => 'true').exactly(1).times
        @manifest.send(:evaluate_recipes)
      end

      it "creates new resources" do
        @manifest.send(:evaluate_recipes)
        @manifest.puppet_resources[Puppet::Type::Exec].keys.sort.should == ['bar', 'foo']
      end

      it "can acess a flat array of resources" do
        @manifest.send(:flat_resources).should == []
      end

    end

    describe "when executed" do

      it "calls evaluate_recipes and apply" do
        @manifest.should_receive(:evaluate_recipes)
        @manifest.should_receive(:apply)
        @manifest.execute
      end

      it "returns true" do
        @manifest.execute.should be_true
      end

      it "cannot be executed again" do
        @manifest.execute.should be_true
        @manifest.execute.should be_false
      end

    end

    describe "after execution" do

      before(:each) do
        @manifest = ProvidedViaModules.new
        @manifest.execute
      end

      it "allows creation of other similar resources" do
        m = PassingArguments.new
        m.execute.should be_true
      end

    end

    describe "noop setting" do

      it "is not set when calling execute" do
        @manifest.execute
        Puppet[:noop].should == false
      end

      it "is not set when calling execute!" do
        @manifest.execute!
        Puppet[:noop].should == false
      end

      describe "noop" do
        it "sets the noop setting and calls execute" do
          @manifest.should_receive(:execute) do
            Puppet[:noop].should == true
          end
          @manifest.noop
        end

        it "cleans up after itself" do
          @manifest.noop
          Puppet[:noop].should == false
        end
      end

      describe "noop!" do
        it "sets the noop setting and calls execute!" do
          @manifest.should_receive(:execute!) do
            Puppet[:noop].should == true
          end
          @manifest.noop!
        end

        it "cleans up after itself" do
          @manifest.noop!
          Puppet[:noop].should == false
        end
      end
    end

  end

  describe "that subclasses an existing manifest" do

    before(:each) do
      @manifest = RequiresMetViaMethodsSubclass.new
    end

    it "inherits recipes from the parent class" do
      @manifest.class.recipes.map(&:first).should include(:foo, :bar)
      @manifest.class.recipes.first.first.should == :foo
    end

    it "appends recipes created in the subclass" do
      @manifest.class.recipes.map(&:first).should include(:baz)
      @manifest.class.recipes.last.first.should == :baz
    end

    it "merges it's configuration with that of the parent" do
      @manifest.class.configuration[:foo].should == :bar
      @manifest.class.configuration[:baz].should == :bar
    end

    it "deep_merges it's configuration with that of the parent" do
      @manifest.class.configuration[:nested_hash][:nested_baz].should == :bar
      @manifest.class.configuration[:nested_hash][:nested_foo].should == :bar
    end

    it "is able to add configuration parameters on the instance" do
      @manifest.configure 'boo' => :bar
      @manifest.configuration[:boo].should == :bar
      @manifest.class.configuration[:boo].should == :bar
    end

  end

  describe "template" do
    it "requires template_root to be configured" do
      expect { BlankManifest.new.template('some_template.conf') }.to raise_error
    end

    it "returns the ERB'ed contents of a file" do
      File.should_receive(:read).with('my/templates/live/here/some_template.conf.erb').and_return("1 plus 2 is <%= 1 + 2 %>")
      WithTemplateRoot.new.template('some_template.conf.erb').should == "1 plus 2 is 3"
    end

    it "supports sending a context" do
      File.should_receive(:read).with('my/templates/live/here/some_template.conf.erb').and_return("1 plus 2 is <%= sum %>")
      WithTemplateRoot.new.template('some_template.conf.erb', :sum => 3).should == "1 plus 2 is 3"
    end
  end

end
