module ShadowPuppet
  # ===Example
  #
  # Given a template (my_template.conf.erb) that looks like:
  #   foo: bar
  #   hostname: <%= hostname %>
  #   apple: banana
  #   ip: <%= ip %>
  #
  # Render it to a string using:
  #   template = ShadowPuppet::Template.new("my_template.conf.erb", :hostname => "Prometheus", :ip => "1.2.3.4")
  #   template.render
  #
  # Result:
  #   foo: bar
  #   hostname: Prometheus
  #   apple: banana
  #   ip: 1.2.3.4
  class Template
    def initialize(file, context = {})
      @file = file
      setup_context(context)
    end

    # render the ERB to text
    def render
      ERB.new(File.read(@file)).result(binding)
    end

    protected
    # Define a getter for each item in the context on the singleton class
    def setup_context(context)
      context.each do |key,value|
        singleton_class.send(:define_method, key) { value }
      end
    end

    # Access the singleton class
    def singleton_class
      class << self
        self
      end
    end
  end
end

