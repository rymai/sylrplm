#Instance utils, creates accessor and create object with merge options.
#=Install
# gem install instanceoptions
#=Simple use
# require 'instanceoptions'
# class Foo
#   include InstanceOptions
# end
# f=Foo.new
# f.attr_accessor(:test)
# f.test=123
# p f.test   #=> '123'
# f.bar=456  #=> raise error 'undefined method'
#=Merge argument in instance
# require 'instanceoptions'
# class Bar
#   DEFAULT_OPTIONS={:name => 'my name', :city => 'my city', :address => 'my address'}
#   include InstanceOptions
#   def initialize(options={})
#     @options=options   #=> The name @options is mandatory
#     instance_options(DEFAULT_OPTIONS)  #=> call method instance_options with hash
#    end
# end
# b=Bar.new 
# b.inspect  #=> #Bar:0xb79e9730 @city="my city", @address="my address", @options={}, @name="my name"
# b.city     #=> 'my city'
# b.city='other' 
# b.city     #=> 'other'
#
# b=Bar.new :name => 'Shairon', :city => 'Gyn'
# b.inspect  #=> #Bar:0xb79e4ba4 @city="Gyn", @address="my address", @name="Shairon", @options={:name=>"Shairon", :city=>"Gyn"} 
# b.city     #=> 'Gyn'
#
# b=Bar.new :name => 'Tom', :address => 'can not say!', :country => 'Japan'  # NoMethodError: undefined method `country=' for Bar:0xb79de7f4
#
# b=Bar.new
# b.attr_accessor(:country)
# b.country='Brazil'
# b.country    #=> 'Brazil'
# b.inspect    #=> #Bar:0xb79dbe28 @city="my city", @country="Brazil", @address="my address", @options={}, @name="my name"
module InstanceOptions
  #Creates method and instance variable for read.
  def attr_reader(*args)
    sym_args=args_to_sym(args)
    sym_args.each do |value|
      self.instance_eval("def #{value}; @#{value};end;")
    end
  end
  #Creates method and instance variable for write.
  def attr_writer(*args)
    sym_args=args_to_sym(args)
    sym_args.each do |value|
      self.instance_eval("def #{value}=(arg); @#{value}=arg;end;")
    end
    
  end
  #Equivalent to attr_reader and attr_writer
  def attr_accessor(*args)
    attr_reader(*args)
    attr_writer(*args)
  end
  
  def set_instance_options(options) # :nodoc: 
    options.each do |k,v|
      self.send(k.to_s+"=",v)      
    end
  end
  
  def initialize_default_options(options) # :nodoc: 
    
    options.each do |k,v|
      attr_accessor(k)
      self.send(k.to_s+'=',v)      
    end
  end
  
  #Creates through of the hash methods accessors for each entries and set values
  def instance_options(default_options)
    initialize_default_options(default_options)
    set_instance_options(@options)
  end

  private
  
  def args_to_sym(args) # :nodoc:
    args.map{|v| v.to_s.to_sym }
  end

end



