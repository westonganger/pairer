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
