module Pairer
  class CleanupBoardsJob < ApplicationJob

    def perform
      Board.where.not(org_id: Pairer.allowed_org_ids).destroy_all
    end

  end
end
