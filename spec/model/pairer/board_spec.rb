require 'spec_helper'

RSpec.describe Pairer::Board, type: :model do

  let(:board) { Pairer::Board.create!(org_id: Pairer.allowed_org_ids.first, password: :foobar) }

  context "shuffle" do
    it "assigns the correct iteration number" do
      skip "TODO"
    end

    it "assigns all roles" do
      skip "TODO"
    end

    it "assigns all unlocked users" do
      skip "TODO"
    end

    it "works with locked users" do
      skip "TODO"
    end

    it "works with locked groups" do
      skip "TODO"
    end

    it "deletes groups without people" do
      skip "TODO"
    end

    it "deletes old untracked groups" do
      skip "TODO"
    end

    it "deletes short-lived re-shuffled groups" do
      skip "TODO"
    end
  end

  context "stats" do
    it "works" do
      expect(board.stats).to eq([])

      skip "TODO"

      expect(board.stats.first).to include("have recently pairer 1 times")
    end
  end

end
