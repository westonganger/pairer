require "pairer/engine"
require "pairer/config"

module Pairer

  def self.config(&block)
    c = Pairer::Config

    if block_given?
      block.call(c)
    else
      return c
    end
  end

end

if RUBY_VERSION.to_f <= 2.6 && !Array.new.respond_to?(:intersection)
  Array.class_eval do
    def intersection(other)
      self & other
    end
  end
end
