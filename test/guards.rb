require 'test/helpers'

stripe ||= Functor.new do
  given( guard { |x| x % 2 == 0 } ) { 'white' }
  given( guard { |x| x % 2 == 1 } ) { 'silver' }
end

describe "Dipatch should support guards" do
  
  specify "allowing you to use odd or even numbers as a dispatcher" do
    [*0..9].map( &stripe ).should == %w( white silver ) * 5
  end
  
end
  