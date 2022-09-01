require 'spec_helper'

RSpec.describe Pairer, type: :model do

  it "allowed_org_ids" do
    expect Pairer.allowed_org_ids.is_a?(Array)
    Pairer.allowed_org_ids = ["foo", "bar"]
    expect(Pairer.allowed_org_ids).to eq(["foo", "bar"])
  end

end
