module Pairer
  class Board < ApplicationRecord
    RECENT_RESHUFFLE_DURATION = 1.minute.freeze
    NUM_CANDIDATE_GROUPINGS = 5

    has_many :people, class_name: "Pairer::Person", dependent: :destroy
    has_many :groups, class_name: "Pairer::Group", dependent: :destroy

    validates :name, presence: true
    validates :org_id, presence: true, inclusion: {in: ->(x){ Pairer.config.allowed_org_ids }}
    validates :password, presence: true, uniqueness: {message: "invalid password, please use a different one", scope: :org_id}
    validates :current_iteration_number, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
    validates :num_iterations_to_track, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: ->(x){ Pairer.config.max_iterations_to_track } }
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
        self[:roles] = val.map{|x| x.presence&.strip }.uniq(&:downcase).compact.sort.join(";;")
      else
        raise "invalid behaviour"
      end
    end

    def roles_array
      self[:roles]&.split(";;") || []
    end

    def shuffle!
      new_groups = []

      prev_iteration_number = current_iteration_number
      next_iteration_number = current_iteration_number + 1

      available_person_ids = people.select{|x| !x.locked? }.collect(&:public_id)
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

          available_person_ids = (available_person_ids - g.person_ids_array)

          available_roles = (available_roles - new_group.roles_array)
        else
          ### Retain Position of Locked People within Existing Groups
          
          group_locked_person_ids = (g.person_ids_array - available_person_ids)

          if group_locked_person_ids.any?
            new_group = groups.new(
              board_iteration_number: next_iteration_number,
              roles: [],
              person_ids: group_locked_person_ids,
            )

            new_groups << new_group

            available_person_ids = (available_person_ids - g.person_ids_array)
          end
        end
      end

      self.increment!(:current_iteration_number)

      if available_person_ids.any?
        pair_stats_hash = stats_hash_for_two_pairs

        ### Assign People to Non-Full Unlocked Groups
        new_groups.select{|x| !x.locked? }.each do |g|
          break if available_person_ids.empty?

          num_to_add = self.group_size - g.person_ids_array.size

          next if num_to_add <= 0

          if available_person_ids.size < num_to_add
            ### Add to group whatever is left
            
            g.person_ids = g.person_ids_array + available_person_ids

            available_person_ids = []

            break
          end

          group_size_combinations = available_person_ids.combination(num_to_add).map{|x| x + g.person_ids_array }.shuffle

          ### Choose group using minimum score
          chosen_person_ids = group_size_combinations.min_by do |person_ids|
            person_ids.combination(2).map(&:sort).sum{|k| pair_stats_hash[k] || 0 }
          end

          g.person_ids = (g.person_ids_array | chosen_person_ids).sort
        end

        ### Assign People to New Groups
        while available_person_ids.any? do
          if available_person_ids.size <= self.group_size
            ### Create group using whats left
            
            new_groups << groups.new(
              board_iteration_number: next_iteration_number,
              person_ids: available_person_ids,
            )

            available_person_ids = []
          else
            group_size_combinations = available_person_ids.combination(self.group_size).to_a.shuffle

            ### Choose group using minimum score
            chosen_person_ids = group_size_combinations.min_by do |person_ids|
              person_ids.combination(2).map(&:sort).sum{|k| pair_stats_hash[k] || 0 }
            end

            new_groups << groups.new(
              board_iteration_number: next_iteration_number,
              person_ids: chosen_person_ids,
            )

            available_person_ids = (available_person_ids - chosen_person_ids)
          end
        end

        ### Shuffle Roles
        available_roles = available_roles.shuffle

        unlocked_new_groups = new_groups.select{|x| !x.locked? }

        ### Assign Roles to Groups
        available_roles.in_groups(unlocked_new_groups.size, false).each_with_index do |roles, i|
          unlocked_new_groups[i].roles = unlocked_new_groups[i].roles_array + roles
          available_roles = available_roles - roles
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
      array = []

      stats_hash_for_two_pairs.sort_by{|k,count| -count }.each do |person_ids, count|
        array << [person_ids, count]
      end

      return array
    end

    private
    
    def stats_hash_for_two_pairs
      h = {}

      tracked_groups.each do |group|
        group_person_ids = group.person_ids_array

        ### For combinations size, we use 2 instead of self.group_size as we are running stats on pairs, not groups
        if group_person_ids.size == 1
          h[group_person_ids] ||= 0
          h[group_person_ids] += 1
        else
          combinations = group_person_ids.combination(2)

          combinations.map{|x| x.sort }.each do |sorted_pair_person_ids|
            h[sorted_pair_person_ids] ||= 0
            h[sorted_pair_person_ids] += 1
          end
        end
      end

      return h
    end

  end
end
