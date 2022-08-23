require 'spec_helper'

RSpec.describe Pairer, type: :model do

  it "allowed_org_names" do
    expect Pairer.allowed_org_names.is_a?(Array)
    Pairer.allowed_org_names = ["foo", "bar"]
    expect(Pairer.allowed_org_names).to eq(["foo", "bar"])
  end

end
