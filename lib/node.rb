# frozen_string_literal: true

require 'erb'

def protect_against_forgery?; end

def protect_against_forgery; end

class Node
  DEFAULT_OPTIONS = {
    label: 'Click Here',
    url: '#',
    title: '',
    target: '',
    icon: '',
    icon_open: '',
    event_name: 'href',
    open: true,
    parent: '',
    id: '',
    link_to_remote: nil,
    link_to: nil,
    # syl
    js_name: 'r',
    obj_child: nil,
    link: nil,
    quantity: nil
  }.freeze

  include ActionView::Helpers::UrlHelper
  include ActionView::Helpers::PrototypeHelper
  include ActionView::Helpers::JavaScriptHelper
  include ERB::Util

  DEFAULT_OPTIONS.keys.each do |method_name|
    define_method method_name do
      @options[method_name]
    end
    define_method "#{method_name}=" do |value|
      @options[method_name] = value
    end
  end

  def initialize(options = {}, html_options = {}, &block)
    @nodes = []
    @options = DEFAULT_OPTIONS.merge(options)

    # @id=options[:id] || self.object_id.abs
    if options[:link_to_remote]
      internal_link_to_remote(@label, options[:link_to_remote], html_options)
    end

    if options[:link_to]
      internal_link_to(@label, options[:link_to], *html_options.to_a)
    end
    yield(@nodes) if block
  end

  def <<(node)
    @nodes << node
  end

  def id
    options[:id]
    # return @id || self.object_id.abs
  end

  def link
    @options[:link]
  end

  def label
    @options[:label]
  end

  def title
    @options[:title]
  end

  def url
    @options[:url]
  end

  def child(options = {}, html_options = {})
    case options
    when Node
      @nodes << options
    when Hash
      n = Node.new(options, html_options)
      yield n if block_given?
      child(n)
      n
    else
      raise Exception, "Unknow arguments #{node.class}"
    end
  end

  def internal_link_to(name, options = {}, *parameters_for_method_reference)
    @url = url_formater(options, parameters_for_method_reference).to_s
    @label = name
  end

  def internal_link_to_remote(name, options = {}, _html_options = {})
    @controller = options[:base]
    options.delete :base
    @request = @controller.request
    @label = name
    @event_name = 'onclick'
    @url = remote_function(options)
  end

  def nodes
    if block_given?
      yield @nodes
    else
      @nodes
    end
  end

  # syl
  attr_writer :nodes

  # syl
  def label=(new_label)
    @options[:label] = new_label
  end

  def id
    @options[:id]
  end

  def obj_child
    @options[:obj_child]
  end

  def link
    @options[:link]
  end

  def quantity
    @options[:quantity]
  end

  def quantity=(new_quantity)
    @options[:quantity] = new_quantity
  end

  def equals?(other_node)
    fname = "Node:#{__method__}"
    # LOG.debug(fname){"#{other_node.obj_child} equals?(#{self.obj_child})"}
    unless obj_child.nil? || other_node.obj_child.nil?
      ret = obj_child.ident == other_node.obj_child.ident
      ret = label == other_node.label if ret == false
    end
    LOG.debug(fname) { "equals?: #{other_node.obj_child.ident} == #{obj_child.ident} = #{ret}" } if ret
    ret
  end

  def remove(node)
    fname = "Node:#{__method__}"
    LOG.debug(fname) { "remove #{node} size=#{@nodes.size}" }
    @nodes.each do |nod|
      if nod.id == node.id
        LOG.debug(fname) { "#{node} equals #{nod}" }
        @nodes.delete(nod)
      end
    end
  end

  def size
    @nodes.size
  end

  # syl pour la somme des noeuds de l'arbre
  def size_all
    fname = "Node:#{__method__}"
    ret = 0
    level = 0
    begin
      ret = size_all_(ret, level)
    rescue Exception => e
      LOG.error(fname) { "EXCEPTION during nodes size calculation: #{e} " }
      ret = -1
    end
    ret
  end

  def to_s
    fname = "Node:#{__method__}"
    # syl @nodes.to_s
    LOG.debug(fname) { '>>>>>>' }
    ret = "#{@nodes.count}:#{@nodes}"
    LOG.debug(fname) { '<<<<<<' }
    ret
  end

  def size_all_(ret, level)
    fname = "Node:#{__method__}"
    blank = '>'.rjust(level)
    msg = "#{blank} lev=#{level} nb=#{nodes.size} #{ret}"
    msg += " #{link.father.ident_plm} #{link.relation.name} #{link.child.ident_plm}" unless link.nil?
    # puts msg
    if level < 50
      level += 1
      nodes.each do |nod|
        ret = 1 + nod.size_all_(ret, level)
      end
    else
      raise Exception, 'Too many levels, certainly because of loop in links'
    end
    # LOG.debug(fname){"<<<level=#{level}, ret=#{ret}"}
    ret
  end
    def empty?
        self.nil? || self.size==0
    end
  private

  def url_formater(options, parameters_for_method_reference)
    if options.is_a? Hash
      begin
        @controller = options[:base]
        options.delete :base
        @request = @controller.request
      rescue StandardError => e
        options = "Controller not found #{e}"
      end
    end
    options.is_a?(String) ? options : url_for(options, *parameters_for_method_reference)
  end
end
