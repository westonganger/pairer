require 'spec_helper'

RSpec.describe Pairer::Board, type: :model do

  let!(:board) { Pairer::Board.create!(org_id: Pairer.allowed_org_ids.first, password: :foobar) }

  after do
    ENV.delete('DELETE_RECENT_RESHUFFLED')
  end

  context "shuffle" do
    it "incrementes the iteration number" do
      3.times.each do |i|
        board.people.create!(name: i)
      end

      expect(board.current_iteration_number).to eq(0)

      board.shuffle!

      expect(board.current_iteration_number).to eq(1)
      expect(board.groups.last.board_iteration_number).to eq(1) ### verify without current_groups logic
      expect(board.current_groups.size).to eq(2)
      expect(board.current_groups.map{|x| x.board_iteration_number}.uniq).to eq([1]) ### verify all current_groups

      board.shuffle!

      expect(board.current_iteration_number).to eq(2)
      expect(board.groups.last.board_iteration_number).to eq(2) ### verify without current_groups logic
      expect(board.current_groups.size).to eq(2)
      expect(board.current_groups.map{|x| x.board_iteration_number}.uniq).to eq([2]) ### verify all current_groups
    end

    it "assigns all roles" do
      board.update!(roles: ["foo","bar","1","2","3"])

      3.times.each do |i|
        board.people.create!(name: i)
      end

      board.shuffle!

      expect(board.roles_array.size).to eq(5)

      expect(board.current_groups.sum{|x| x.roles_array.size }).to eq(5)
    end

    it "assigns all unlocked users" do
      3.times.each do |i|
        board.people.create!(name: i)
      end

      board.shuffle!

      expect(board.people.size).to eq(3)

      expect(board.current_groups.sum{|x| x.person_ids_array.size }).to eq(3)
    end

    it "doesnt shuffle locked people outside of groups" do
      3.times.each do |i|
        board.people.create!(name: i, locked: true)
      end

      expect(board.current_groups.size).to eq(0)

      board.shuffle!

      expect(board.current_groups.size).to eq(0)
    end

    it "leaves locked groups on the board" do
      3.times.each do |i|
        board.people.create!(name: i)
      end

      3.times.each do |i|
        board.groups.create!(
          board_iteration_number: board.current_iteration_number, 
          locked: true, 
          person_ids: ["#{i}"],
        )
      end

      expect(board.current_groups.size).to eq(3)

      board.shuffle!

      expect(board.current_groups.size).to eq(5)
    end

    it "deletes groups without people, even if locked" do
      3.times.each do |i|
        board.people.create!(name: i)
      end

      3.times.each do |i|
        board.groups.create!(board_iteration_number: board.current_iteration_number)
      end

      ### Check for locked groups
      board.groups.create!(board_iteration_number: board.current_iteration_number, locked: true)

      expect(board.groups.size).to eq(4)

      prev_group_ids = board.groups.pluck(:id)

      board.shuffle!

      expect(board.groups.size).to eq(2)
      expect(prev_group_ids.intersection(board.groups.map(&:id))).to eq([])
    end

    it "deletes old untracked groups" do
      board.update_columns(num_iterations_to_track: 2)

      3.times.each do |i|
        board.people.create!(name: i)
      end

      expect(board.groups.size).to eq(0)

      board.shuffle!

      expect(board.groups.size).to eq(2)
      
      board.shuffle!

      expect(board.groups.size).to eq(4)
      
      board.shuffle!

      expect(board.groups.size).to eq(4)
    end

    it "deletes short-lived re-shuffled groups" do
      ENV['DELETE_RECENT_RESHUFFLED'] = "true"

      5.times.each do |i|
        board.people.create!(name: i)
      end

      expect(board.groups.size).to eq(0)

      board.shuffle!

      expect(board.groups.size).to eq(3)

      board.shuffle!

      expect(board.groups.size).to eq(3)
    end

    it "obeys config for group size" do
      board.update_columns(group_size: 3)

      3.times.each do |i|
        board.people.create!(name: i)
      end

      board.shuffle!

      expect(board.groups.size).to eq(1)
    end

    it "ensures the position of locked people in existing groups are preserved across shuffle" do
      board.update_columns(group_size: 3)

      2.times.each do |i|
        board.people.create!(name: i, locked: true)
      end

      4.times.each do |i|
        board.people.create!(name: "#{i}-#{i}")
      end

      locked_person_ids = board.people.select(&:locked?).map(&:public_id)

      group = board.groups.create!(
        board_iteration_number: board.current_iteration_number, 
        person_ids: locked_person_ids,
      )

      board.shuffle!

      expect(locked_person_ids.size).to eq(2)
      expect(board.current_groups.first.person_ids_array.size).to eq(3)
      expect(board.current_groups.first.person_ids_array.intersection(locked_person_ids).size).to eq(2)

      ### Check a second time
      board.shuffle!

      expect(locked_person_ids.size).to eq(2)
      expect(board.current_groups.first.person_ids_array.size).to eq(3)
      expect(board.current_groups.first.person_ids_array.intersection(locked_person_ids).size).to eq(2)
    end

    it "reliably produces unique groups of people" do
      board.update_columns(group_size: 2)

      4.times.each do |i|
        board.people.create!(name: i)
      end

      unique_count = 0
      total_count = 100

      total_count.times.each do |i|
        board.groups.delete_all

        board.shuffle!

        first_groupings = board.current_groups.map{|x| x.person_ids_array }

        board.shuffle!

        second_groupings = board.current_groups.map{|x| x.person_ids_array }

        if first_groupings.map(&:sort) != second_groupings.map(&:sort)
          unique_count += 1
        end
      end

      ### Can be flaky but should consistently this test, if failing re-run and see if it passes
      expect((unique_count.to_f/total_count).round(2)).to be >= 0.80
    end
  end

  context "stats" do
    it "tracks stats" do
      5.times.each do |i|
        board.people.create!(name: i)
      end

      2.times.each do |i|
        board.people.create!(name: "#{i}-#{i}", locked: true)
      end

      stats = board.stats
      expect(stats.size).to eq(21)
      expect(stats.map(&:last).uniq.sort).to eq([0])

      board.shuffle!

      stats = board.stats
      expect(stats.size).to eq(22) ### 1 increase is for solo groups
      expect(stats.map(&:last).uniq.sort).to eq([0,1])
    end

    it "shows 0 in stats for pairs that have not yet paired" do
      3.times.each do |i|
        board.people.create!(name: i)
      end

      stats = board.stats
      expect(stats.size).to eq(3)
      expect(stats.map(&:last)).to eq([0, 0, 0])
    end

    it "shows number in stats for solos" do
      3.times.each do |i|
        board.people.create!(name: i)
      end

      board.shuffle!

      stats = board.stats
      expect(stats.detect{|person_ids, _count| person_ids.size == 1 }.last).to eq(1)
    end

    it "doesnt show zero for solos" do
      3.times.each do |i|
        board.people.create!(name: "#{i}-#{i}", locked: true)
      end

      stats = board.stats
      expect(stats.detect{|person_ids, _count| person_ids.size == 1 && count == 0 }).to eq(nil)
    end
  end

end
