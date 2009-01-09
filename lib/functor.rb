require "#{File.dirname(__FILE__)}/object"
require 'rubygems'
require 'metaid'

class Functor
  
  module Method
    
    def self.copy_functors( functors )
      r = {} ; functors.each do | name, functor |
        r[ name ] = functor.clone
      end
      return r
    end
    
    def self.included( k )
      
      def k.functors
        @__functors ||= superclass.respond_to?( :functors ) ? 
          Functor::Method.copy_functors( superclass.functors ) : {}
      end
      
      def k.functor( name, *pattern, &block )
        name = name.to_sym
        f = ( functors[ name ] ||=  Functor.new )
        f.register( pattern )
        f.meta_def "functo_#{pattern.hash}" do |caller, *args|
          caller.instance_exec *args, &block
        end
        unless respond_to?( name )
          define_method( name ) do | *args |
            begin
              signature = f.match( *args )
              f.send "functo_#{signature}", self, *args
            rescue NoMethodError
              raise ArgumentError.new( "No functor matches the given arguments for method :#{name}." )
            end
          end 
        end
      end
      
      def k.functor_with_self( name, *pattern, &block )
        name = name.to_sym
        f = ( functors[ name ] ||=  Functor.new )
        f.register( pattern )
        f.meta_def "functo_#{pattern.hash}" do |caller, *args|
          caller.instance_exec *args, &block
        end
        unless respond_to?( name )
          define_method( name ) do | *args |
            begin
              signature = f.match( self, *args )
              f.send "functo_#{signature}", self, *args
            rescue NoMethodError
              raise ArgumentError.new( "No functor matches the given arguments for method :#{name}." )
            end
          end
        end
      end
      
    end
  end
  
  
  def initialize( &block )
    @patterns = []
    @associations = {}
    yield( self ) if block_given?
  end
  
  def initialize_copy( from )
    @patterns, @associations = from.instance_eval { [@patterns.clone, @associations.clone] }
  end
  
  def given( *pattern, &action )
    register pattern
    name = "functo_#{pattern.hash}"
    class << self; self; end.instance_eval do
      define_method( name, action )
    end
  end
  
  def register( pattern )
    @patterns.unshift pattern
  end
  
  def call( *args, &block )
    signature = match( *args, &block )
    send "functo_#{signature}", *args
  end
  
  def []( *args, &block )
    call( *args, &block )
  end
  
  def to_proc ; lambda { |*args| self.call( *args ) } ; end
    
  def match( *args, &block )
    arg_sig = args.hash
    if pattern_sig = @associations[arg_sig]
      pattern_sig
    else
      args << block if block_given?
      pattern = @patterns.find { | p | match?( args, p ) }
      raise ArgumentError.new( "No functor matches the given arguments." ) unless pattern
      @associations[arg_sig] = pattern.hash
    end
  end
  
  private
  
  def match?( args, pattern )
    args.zip( pattern ).all? { | arg, pat | pair?( arg, pat ) } if args.length == pattern.length
  end
  
  def pair?( arg, pat )
    ( pat.respond_to? :call and pat.call( arg ) ) or pat === arg
  end
    
end