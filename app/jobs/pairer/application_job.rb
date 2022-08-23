module Pairer
  class ApplicationJob < ActiveJob::Base
    self.queue_adapter = :async
  end
end
