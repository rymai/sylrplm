#--
# Copyright (c) 2008-2009, John Mettraux, jmettraux@gmail.com
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# Made in Japan.
#++

#
# Process definitions are tracked via this record class.
#
class Definition < ActiveRecord::Base
  include Models::SylrplmCommon
  include LinksMixin
  #
  #has_many :group_definitions, :dependent => :delete_all
  #has_many :groups, :through => :group_definitions
  #has_many :role_definitions, :dependent => :delete_all
  #has_many :roles, :through => :role_definitions
  has_and_belongs_to_many :roles
  #
  # validations
  validates_presence_of :name, :uri
  #
  validates_uniqueness_of :name

  def validate
    super
    validate_uri
  end

  def validate_uri
    content = (open(local_uri).read rescue nil)
    unless content
      errors.add_to_base("#{full_uri} points to nothing")
      return
    end
    @_tree = (RuotePlugin.ruote_engine.get_def_parser.parse(content) rescue nil)
    errors.add_to_base(
    "#{full_uri} seems not to contain a process definition"
    ) unless @_tree
  end
  
	def name_translate
		PlmServices.translate("definition_#{name}")
	end
  
  #
  # Fetching the process description
  #
  def before_save
    self.description ||= OpenWFE::ExpressionTree.get_description(@_tree)
  end

  def ident; name; end

  #
  # Finds all the definitions the user has the right to see
  #
  def self.find_all_for (user)
    all = find(:all)
    unless user.nil?
    	user.is_admin? ? all : all.select { |d| ! d.is_special? }
    else
    	[]
    end
  end
  #
  # Returns true if the definition is special (ie it represents the right
  # to launch an embedded or an untracked definition)
  #
  def is_special?
    ['*embedded*', '*untracked*'].include?(self.name)
  end

  #
  # The URI for web links
  #
  def full_uri
    return nil unless self.uri
    self.uri.index('/') ? self.uri : "/definitions/#{self.uri}"
  end

  #
  # The URI for launching
  #
  def local_uri
    return nil unless self.uri
    u = full_uri
    u[0, 1] == '/' ? "#{RAILS_ROOT}/public#{u}" : u
  end

  def usable?
    f=local_uri
    LOG.info {"local_uri="+f.to_s}
    File.exists?(f) unless f.nil?
  end
  #
  # Returns the initial workitem payload at launch time (launchitem)
  #
  def launch_fields_hash_ori
    launch_fields ?
    ActiveSupport::JSON.decode(launch_fields) : { 'attribut_0' => 'valeur_0' , 'attribut_1' => 'valeur_1'}
  end

  def launch_fields_hash
    unless launch_fields.nil?
      ret= ActiveSupport::JSON.decode(launch_fields)
    else
      ret={}
      #ret['attribut']  = 'valeur'
    end
    #puts "definition.launch_fields_hash:"+ret.inspect
    ret
  end

  def definition
    ''
  end

  def definition= (s)
#    puts "definition.definition("+s.inspect+")"
    return if s.blank?
    pref = "#{RAILS_ROOT}/public"
    base = "/definitions/#{OpenWFE.ensure_for_filename(self.name)}"
    i = ''
    fn = pref + base + i.to_s + '.def'

    while File.exist?(fn)
      i = (i == '') ? 1 : i + 1
      fn = pref + base + i.to_s + '.def'
    end

    File.open(fn, 'w') { |f| f.write(s) }

    self.uri = base + i.to_s + '.def'
  end


  protected

  def links (opts={})
    linkgen = LinkGenerator.new(opts[:request])
    [
      linkgen.hlink('via', 'definitions'),
      linkgen.hlink('self', 'definitions', self.id.to_s)
    ]
  end
end

