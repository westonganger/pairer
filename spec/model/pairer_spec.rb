require 'spec_helper'

RSpec.describe Pairer, type: :model do

  context "allowed_org_ids" do
    before do
      @prev_allowed_org_ids = Pairer.config.allowed_org_ids
    end

    after do
      Pairer.config.allowed_org_ids = @prev_allowed_org_ids
    end

    it "allows array values" do
      expect Pairer.config.allowed_org_ids.is_a?(Array)
      Pairer.config.allowed_org_ids = ["foo", "bar"]
      expect(Pairer.config.allowed_org_ids).to eq(["foo", "bar"])
    end

    it "does not allow non-array values" do
      expect{ Pairer.config.allowed_org_ids = "foo" }.to raise_error(RuntimeError)
    end
  end

  context "max_iterations_to_track" do
    before do
      @prev_max_iterations_to_track = Pairer.config.max_iterations_to_track
    end

    after do
      Pairer.config.max_iterations_to_track = @prev_max_iterations_to_track
    end

    it "allows integer values" do
      expect Pairer.config.allowed_org_ids.is_a?(Integer)
      Pairer.config.max_iterations_to_track = 10
      expect(Pairer.config.max_iterations_to_track).to eq(10)
    end

    it "doesnt allow 0 values" do
      expect{ Pairer.config.max_iterations_to_track = 0 }.to raise_error(RuntimeError)
    end

    it "doesnt allow negative values" do
      expect{ Pairer.config.max_iterations_to_track = -1 }.to raise_error(RuntimeError)
    end

    it "does not allow non-integer values" do
      expect{ Pairer.config.max_iterations_to_track = "foo" }.to raise_error(RuntimeError)
    end
  end

end
