module Pairer
  class CleanupBoardsJob < ApplicationJob

    def perform
      Board.where.not(org_name: Pairer.allowed_org_names).destroy_all
    end

  end
end
