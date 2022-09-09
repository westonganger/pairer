require 'spec_helper'

RSpec.describe Pairer::BoardsController, type: :request do
  def org_id
    Pairer.allowed_org_ids.first
  end

  def org_login
    post pairer.sign_in_path, params: {org_id: org_id}
    assert_equal(response.status, 302)
    assert_redirected_to pairer.boards_path
  end

  def board_login
    @board = Pairer::Board.create!(name: :foobar, password: :foo_password, org_id: org_id)

    get pairer.boards_path, params: {password: @board.password}
    assert_equal(response.status, 302)
    assert_redirected_to pairer.board_path(@board)
  end

  def logout
    get pairer.sign_out_path
    assert_equal(response.status, 302)
    assert_redirected_to pairer.sign_in_path
  end

  before do
    Pairer::Board.all.destroy_all

    org_login

    board_login
  end

  after do
    Pairer::Board.all.destroy_all

    logout
  end

  it "index" do
    ### Test signed in
    get pairer.boards_path
    assert_equal(response.status, 200)
    assert(response.body.include?("Find Board"))

    logout

    ### Test signed out
    get pairer.boards_path
    assert_equal(response.status, 302)
    assert_redirected_to pairer.sign_in_path
  end

  it "index with invalid org_id" do
    bad_org_id = "something-invalid"

    allow(Pairer).to receive(:allowed_org_ids).and_return([bad_org_id])
    post pairer.sign_in_path, params: {org_id: org_id}
    assert_equal(response.status, 302)
    assert_redirected_to pairer.boards_path

    allow(Pairer).to receive(:allowed_org_ids).and_call_original
    get pairer.boards_path
    assert_equal(response.status, 302)
    assert_redirected_to pairer.sign_in_path
  end

  context "show" do
    it "displays page with no people or roles" do
      get pairer.board_path(@board)
      assert_equal(response.status, 200)

      expect(Nokogiri::XML(response.body).css(".person").size).to eq(0)
      expect(Nokogiri::XML(response.body).css(".roles").size).to eq(0)
    end

    it "displays page with people and roles" do
      @board.update!(roles: ["foo", "bar"])

      3.times.each do |i|
        @board.people.create!(name: i)
      end

      get pairer.board_path(@board)
      assert_equal(response.status, 200)

      expect(Nokogiri::XML(response.body).css(".person").size).to eq(3)
      expect(Nokogiri::XML(response.body).css(".role").size).to eq(2)
    end

    it "displays page when groups are populated" do
      @board.update!(roles: ["foo", "bar"])

      3.times.each do |i|
        @board.people.create!(name: i)
      end

      @board.shuffle!

      get pairer.board_path(@board)
      assert_equal(response.status, 200)

      expect(Nokogiri::XML(response.body).css("tr.group-row").size).to eq(2)
      expect(Nokogiri::XML(response.body).css("tr.group-row .person").size).to eq(3)
      expect(Nokogiri::XML(response.body).css("tr.group-row .role").size).to eq(2)
    end

    it "displays stats" do
      3.times.each do |i|
        @board.people.create!(name: i)
      end

      @board.shuffle!

      expect(@board.stats).not_to be_empty

      get pairer.board_path(@board)
      assert_equal(response.status, 200)

      expect(Nokogiri::XML(response.body).css("table#stats tbody tr").size).to eq(2)
    end

    it "displays a shuffle button" do
      get pairer.board_path(@board)
      assert_equal(response.status, 200)
      assert(response.body.include?("Shuffle"))
    end
  end

  it "update" do
    patch pairer.board_path(@board), params: {
      board: {
        name: "asd", 
        roles: ["bar", "foo"],
        group_size: 5, 
        num_iterations_to_track: 25
      }
    }
    assert_equal(response.status, 302)
    assert_redirected_to pairer.board_path(@board)

    @board.reload

    assert_equal(@board.name, "asd")
    assert_equal(@board.roles_array, ["bar", "foo"])
    assert_equal(@board.group_size, 5)
    assert_equal(@board.num_iterations_to_track, 25)

    patch pairer.board_path(@board), params: {
      board: {
        name: "asd", 
        roles: "foo,bar",
        group_size: 5, 
        num_iterations_to_track: 25
      }
    }
    assert_equal(response.status, 302)
    assert_redirected_to pairer.board_path(@board)

    @board.reload

    assert_equal(@board.name, "asd")
    assert_equal(@board.roles_array, ["bar", "foo"])
    assert_equal(@board.group_size, 5)
    assert_equal(@board.num_iterations_to_track, 25)
  end

  it "destroy" do
    assert_difference ->(){ Pairer::Board.count }, -1 do
      delete pairer.board_path(@board)
      assert_equal(response.status, 302)
      assert_redirected_to pairer.boards_path
    end
  end

  it "shuffle" do
    post pairer.shuffle_board_path(@board)
    assert_equal(response.status, 302)
    assert_redirected_to pairer.board_path(@board)
  end

  it "create_person" do
    assert_difference ->(){ @board.people.count } do
      post pairer.create_person_board_path(@board, name: "some person name")
      assert_equal(response.status, 302)
      assert_redirected_to pairer.board_path(@board)
    end
  end

  it "lock_person" do
    @person = @board.people.create!(name: :foobar)

    post pairer.lock_person_board_path(@board, person_id: @person.to_param)
    assert_equal(response.status, 302)
    assert_redirected_to pairer.board_path(@board)
    assert_equal @person.reload.locked, true

    post pairer.lock_person_board_path(@board, person_id: @person.to_param)
    assert_equal(response.status, 302)
    assert_redirected_to pairer.board_path(@board)
    assert_equal @person.reload.locked, false
  end

  it "delete_person" do
    @person = @board.people.create!(name: :foobar)

    assert_difference ->(){ @board.people.count }, -1 do
      delete pairer.delete_person_board_path(@board, person_id: @person.to_param)
      assert_equal(response.status, 302)
      assert_redirected_to pairer.board_path(@board)
    end
  end

  it "create_group" do
    assert_difference ->(){ @board.groups.count } do
      post pairer.create_group_board_path(@board, group_id: @group.to_param)
      assert_equal(response.status, 302)
      assert_redirected_to pairer.board_path(@board)
    end
  end

  it "update_group" do
    @group = @board.groups.create!(board_iteration_number: 1)

    roles = ["bar", "foo"]

    ### Invalid Roles
    post pairer.update_group_board_path(@board, group_id: @group.to_param, roles: roles)
    assert_equal(response.status, 302)
    assert_redirected_to pairer.board_path(@board)
    assert_equal @group.reload.roles_array, []

    ### Invalid Person Ids
    post pairer.update_group_board_path(@board, group_id: @group.to_param, person_ids: ["foo", "bar"])
    assert_equal(response.status, 302)
    assert_redirected_to pairer.board_path(@board)
    assert_equal @group.reload.person_ids_array, []

    @board.update!(roles: roles)

    ### Valid Roles
    post pairer.update_group_board_path(@board, group_id: @group.to_param, roles: roles)
    assert_equal(response.status, 302)
    assert_redirected_to pairer.board_path(@board)
    assert_equal @group.reload.roles_array, roles.sort

    person = @board.people.create!(name: "Abby")

    person_ids = [person.public_id]

    ### Valid Person Ids
    post pairer.update_group_board_path(@board, group_id: @group.to_param, person_ids: person_ids)
    assert_equal(response.status, 302)
    assert_redirected_to pairer.board_path(@board)
    assert_equal @group.reload.person_ids_array, person_ids
  end

  it "lock_group" do
    @group = @board.groups.create!(board_iteration_number: 1)

    post pairer.lock_group_board_path(@board, group_id: @group.to_param)
    assert_equal(response.status, 302)
    assert_redirected_to pairer.board_path(@board)
    assert_equal @group.reload.locked, true

    post pairer.lock_group_board_path(@board, group_id: @group.to_param)
    assert_equal(response.status, 302)
    assert_redirected_to pairer.board_path(@board)
    assert_equal @group.reload.locked, false
  end

  it "delete_group" do
    @group = @board.groups.create!(board_iteration_number: 1)

    assert_difference ->(){ @board.groups.count }, -1 do
      delete pairer.delete_group_board_path(@board, group_id: @group.to_param)
      assert_equal(response.status, 302)
      assert_redirected_to pairer.board_path(@board)
    end
  end
end
