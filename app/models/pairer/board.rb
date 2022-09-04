module Pairer
  class Board < ApplicationRecord
    RECENT_RESHUFFLE_DURATION = 1.minute.freeze
    NUM_SHUFFLES = 3

    has_many :people, class_name: "Pairer::Person", dependent: :destroy
    has_many :groups, class_name: "Pairer::Group", dependent: :destroy

    validates :name, presence: true
    validates :org_id, presence: true, inclusion: {in: ->(x){ Pairer.allowed_org_ids }}
    validates :password, presence: true, uniqueness: {message: "invalid password, please use a different one", scope: :org_id}
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

    def tracked_groups
      groups
        .order(board_iteration_number: :desc)
        .where("board_iteration_number > #{current_iteration_number - num_iterations_to_track}")
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

    def shuffle!
      unlocked_person_ids = people.select{|x| !x.locked? }.collect(&:public_id)

      new_groups = []

      prev_iteration_number = current_iteration_number
      next_iteration_number = current_iteration_number + 1

      if unlocked_person_ids.any?
        available_roles = roles_array

        ### Build New Groups
        groups.where(board_iteration_number: prev_iteration_number).each do |g|
          if g.locked?
            ### Clone Locked Groups
            
            new_group = g.dup

            new_group.assign_attributes(
              public_id: nil,
              board_iteration_number: next_iteration_number,
            )

            new_groups << new_group

            available_roles = (available_roles - new_group.roles_array)
          else
            ### Retain Position of Locked People within Existing Groups
            
            group_locked_person_ids = (g.person_ids_array - unlocked_person_ids)

            if group_locked_person_ids.any?
              new_group = groups.new(
                board_iteration_number: next_iteration_number,
                roles: [],
                person_ids: group_locked_person_ids,
              )

              new_groups << new_group
            end
          end
        end

        self.increment!(:current_iteration_number)

        ### Shuffle People
        NUM_SHUFFLES.times.each do ### Like a card dealer, we shuffle a few times to improve shuffle
          unlocked_person_ids = unlocked_person_ids.shuffle
        end

        ### Assign People to Non-Full Unlocked Groups
        new_groups.select{|x| !x.locked? }.each do |g|
          this_group_size = g.person_ids_array.size
          num_to_add = self.group_size - this_group_size

          next if num_to_add <= 0

          new_person_ids = unlocked_person_ids.first(num_to_add)

          unlocked_person_ids = unlocked_person_ids - new_person_ids

          g.person_ids = g.person_ids_array + new_person_ids
        end

        ### Assign People to New Groups
        unlocked_person_ids.shuffle.each_slice(self.group_size).each do |x|
          new_groups << groups.new(
            board_iteration_number: next_iteration_number,
            person_ids: x,
          )
        end

        ### Shuffle Roles
        NUM_SHUFFLES.times.each do ### Like a card dealer, we shuffle a few times to improve shuffle
          available_roles = available_roles.shuffle
        end

        unlocked_new_groups = new_groups.select{|x| !x.locked? }

        ### Assign Roles to Groups
        until available_roles.empty?
          available_roles.shuffle.in_groups(unlocked_new_groups.size, false).each_with_index do |roles, i|
            unlocked_new_groups[i].roles = roles
            available_roles = (available_roles - roles)
          end
        end

        ### Save New Groups
        new_groups.each{|x| x.save! }
      end

      ### Delete empty groups
      groups
        .where(person_ids: [nil, ""])
        .each{|x| x.destroy! }

      ### Delete outdated groups
      groups
        .where.not(id: tracked_groups.collect(&:id))
        .each{|x| x.destroy! }

      ### Ensure stats do not contain bogus entries caused by re-shuffling, groups created less than x time ago are deleted upon shuffle
      if !Rails.env.test? || (Rails.env.test? && ENV['DELETE_RECENT_RESHUFFLED'].to_s == "true")
        groups
          .where.not(id: new_groups.collect(&:id))
          .where("#{Pairer::Group.table_name}.created_at >= ?", RECENT_RESHUFFLE_DURATION.ago)
          .each{|x| x.destroy! }
      end

      ### Reload groups to fix any issues with caching after creations and deletions
      groups.reload
        
      return true
    end

    def stats
      stats = {}

      ### Initialize all possible permutations with 0
      people.each_with_index do |p, i|
        next if i+1 == people.size

        people.each_with_index do |p2, i2|
          next if i == i2

          if p2
            sorted_pair_names = [p.name, p2.name].sort

            stats[sorted_pair_names] ||= 0
          end
        end
      end

      person_names_by_public_id = people.pluck(:public_id, :name).to_h

      tracked_groups.each do |group|
        group_person_ids = group.person_ids_array

        group_person_ids.each_with_index do |person_id, i|
          next if i+1 == group_person_ids.size

          person_name = person_names_by_public_id[person_id]

          next if person_name.nil?

          group_person_ids.each_with_index do |other_person_id, i2|
            next if i == i2

            other_person_name = person_names_by_public_id[other_person_id]

            next if other_person_name.nil?

            sorted_pair_names = [person_name, other_person_name].sort

            stats[sorted_pair_names] += 1
          end
        end
      end

      arr = []

      stats.sort_by{|k,count| [-count, k] }.each do |person_names, count|
        arr << [person_names, count]
      end

      return arr
    end

  end
end
