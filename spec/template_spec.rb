require File.dirname(__FILE__) + '/spec_helper.rb'

describe "A template" do
  describe "without any context" do
    it "renders some ERB" do
      File.should_receive(:read).with('some_template.conf.erb').and_return("1 plus 2 is <%= 1 + 2 %>")
      ShadowPuppet::Template.new('some_template.conf.erb').render.should == "1 plus 2 is 3"
    end
  end

  describe "with a context" do
    it "render some ERB" do
      File.should_receive(:read).with('some_template.conf.erb').and_return("2 plus 2 is <%= sum %>")
      ShadowPuppet::Template.new('some_template.conf.erb', :sum => 4).render.should == "2 plus 2 is 4"
    end

    it "only sets up context for the current template" do
      File.should_receive(:read).twice.with('some_template.conf.erb').and_return("2 plus 2 is <%= sum %>")

      ShadowPuppet::Template.new('some_template.conf.erb', :sum => 4).render.should == "2 plus 2 is 4"
      expect do
        ShadowPuppet::Template.new('some_template.conf.erb').render
      end.to raise_error(NameError, /undefined local variable or method .sum./)
    end

    it "allows context to be overridden in the template" do
      erb = <<EOT
<%= var %>
<% var = 5 %>
<%= var %>
EOT
      File.should_receive(:read).with('some_template.conf.erb').and_return(erb)
      ShadowPuppet::Template.new('some_template.conf.erb', :var => 4).render.should == "4\n\n5\n"
    end
  end

end
