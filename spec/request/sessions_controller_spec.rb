require 'spec_helper'

RSpec.describe Pairer::SessionsController, type: :request do
  def org_name
    Pairer.allowed_org_names.first
  end

  def org_login
    post pairer.sign_in_path, params: {org_name: org_name}
    assert_equal(response.status, 302)
    assert_redirected_to pairer.boards_path
  end

  def logout
    get pairer.sign_out_path
    assert_equal(response.status, 302)
    assert_redirected_to pairer.sign_in_path
  end

  before do
    Pairer::Board.all.destroy_all

    org_login
  end

  after do
    Pairer::Board.all.destroy_all

    logout
  end

  it "sign_in" do
    ### Signed in
    get pairer.sign_in_path
    assert_equal(response.status, 302)
    assert_redirected_to pairer.boards_path

    ### Signed out
    logout

    get pairer.sign_in_path
    assert_equal(response.status, 200)
    assert(response.body.include?("Sign In"))

    ### Signed out, passing org name
    post pairer.sign_in_path, params: {org_name: Pairer.allowed_org_names.first}
    assert_equal(response.status, 302)
    assert_redirected_to pairer.boards_path
  end

  it "sign_out" do
    get pairer.sign_out_path
    assert_equal(response.status, 302)
    assert_redirected_to pairer.sign_in_path

  end

end
