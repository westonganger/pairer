module Pairer
  class Board < ApplicationRecord
    has_many :people, class_name: "Pairer::Person", dependent: :destroy
    has_many :groups, class_name: "Pairer::Group", dependent: :destroy

    validates :name, presence: true
    validates :org_name, presence: true, inclusion: {in: ->(x){ Pairer.allowed_org_names }}
    validates :password, presence: true, uniqueness: {message: "invalid password, please use a different one", scope: :org_name}
    validates :current_iteration_number, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
    validates :num_iterations_to_track, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 30 }
    validates :group_size, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

    before_validation on: :create do
      self.name = "New Board"
      self.current_iteration_number = 0
      self.num_iterations_to_track = 15
      self.group_size = 2
    end

    def current_groups
      groups.where(board_iteration_number: current_iteration_number)
    end

    def shuffle!
      unlocked_person_ids = people.select{|x| !x.locked? }.collect(&:public_id)

      new_groups = []

      prev_iteration_number = current_iteration_number
      next_iteration_number = current_iteration_number + 1

      if unlocked_person_ids.any?
        available_roles = roles_array

        groups.where(board_iteration_number: prev_iteration_number).each do |g|
          if g.locked?
            unlocked_person_ids = (unlocked_person_ids - g.person_ids_array)

            new_group = g.dup
            new_group.public_id = nil
            new_group.board_iteration_number = next_iteration_number

            new_groups << new_group

            available_roles = (available_roles - new_group.roles_array)
          end
        end

        self.increment!(:current_iteration_number)

        unlocked_person_ids.shuffle.each_slice(group_size).each do |x|
          new_groups << groups.new(
            board_iteration_number: next_iteration_number,
            person_ids: x,
          )
        end

        unlocked_new_groups = new_groups.select{|x| !x.locked? }

        until available_roles.empty?
          available_roles.shuffle.in_groups(unlocked_new_groups.size, false).each_with_index do |roles, i|
            unlocked_new_groups[i].roles = roles
            available_roles = (available_roles - roles)
          end
        end

        new_groups.each{|x| x.save! }
      end

      ### Delete empty groups
      groups.where(person_ids: [nil, ""]).each{|x| x.destroy! }

      ### Delete outdated groups
      groups.where.not(id: tracked_groups.collect(&:id)).each{|x| x.destroy! }

      ### Ensure stats do not contain bogus entries caused by re-shuffling, groups created less than x time ago are deleted upon shuffle
      groups
        .where.not(id: new_groups.collect(&:id))
        .where("#{Pairer::Group.table_name}.created_at <= ?", 1.minutes.ago).each{|x| x.destroy! }
        
      return true
    end

    def tracked_groups
      groups
        .order(board_iteration_number: :desc)
        .where("board_iteration_number >= #{current_iteration_number - num_iterations_to_track}")
    end

    def stats
      stats = {}

      person_names_by_public_id = people.pluck(:public_id, :name).to_h

      tracked_groups.each do |group|
        person_ids = group.person_ids_array

        person_ids.each_with_index do |x,i|
          next if person_names_by_public_id[x].nil?

          if i != person_ids.size-1
            sorted_pair_names = [
              person_names_by_public_id[x], 
              person_names_by_public_id[person_ids[i+1]],
            ].compact.sort

            if sorted_pair_names.size < 2
              next
            end

            stats[sorted_pair_names] ||= 0
            stats[sorted_pair_names] += 1
          end
        end
      end

      people.each_with_index do |p, i|
        if i != people.size-1
          sorted_pair_names = [p.name, people[i+1].name].sort

          stats[sorted_pair_names] ||= 0
        end
      end

      arr = []

      stats.sort_by{|k,count| [-count, k] }.each do |person_names, count|
        arr << [person_names, count]
      end

      return arr
    end

    def roles=(val)
      if val.is_a?(Array)
        self[:roles] = val.map{|x| x.presence&.strip }.uniq.compact.sort.join(";;")
      else
        raise "invalid behaviour"
      end
    end

    def roles_array
      self[:roles]&.split(";;") || []
    end

  end
end
