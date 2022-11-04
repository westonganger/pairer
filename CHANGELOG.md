# CHANGELOG

### November 3, 2022

- Fix exception on boards#show page after people are deleted
- Dont add new person to list in JS when not created successfully
- Fix issue with shuffle and groups with locked person(s)

### Oct 7, 2022
- Remove unnecessary JS libraries
- Add `Pairer.config`
- Change `Pairer.allowed_org_ids` to `Pairer.config.allowed_org_ids`
- Change `Pairer.max_number_of_iterations` to `Pairer.config.max_number_of_iterations`
- Add `Pairer.config.hash_id_salt` to ensure apps can customize their public_id generation

### September 12, 2022
- Ensure roles dont allow duplicates with uppercase/lowercase
- Ensure persons name uniqueness validation is case-insensitive
- Add configuration value `Pairer.max_number_of_iterations = 100`
- Add better validation error for number of iterations to track
- Increase alert/error message hide timeout for better UX
- Add Test Suite with Github Actions for all Ruby, Rails and DB versions
- Change Shuffle Algorithm to more deterministicly choose the most unique groups
  * Score of each set of people is from the following formula. We generate all possible group combinations of people, given what we have left/available. We choose the group combination by selecting the minimum sum of the number of occurences of all 2-person combinations within te group combination.
  * The algorithm is naive in that it does not attempt to enumerate the very best combinations based on all possible outcomes. It just selects the best combinations for whatever groups are created first, so future iterations of the combinations may not be fully optimal. Non-full unlocked groups with locked-people are assigned people first, then secondly the completely new groups.

### September 8, 2022
- Remove zeros from stats, having zeros is not sustainable because it will make the list massive for larger team sizes

### September 7, 2022
- Attempt to make shuffle algorithm stronger by generating 5 candidate groupings and then choosing the least-common of these groupings based on the stats
- Show solo groupings in the stats

### September 4, 2022
- Write unit tests for Pairer::Board#shuffle and #stats
- Fix bug where recently re-shuffled groups were being included in the stats
- Ensure the position of locked people in existing groups are preserved across shuffle
- Improve shuffling algorithm by shuffling 3 times, like a card dealer we shuffle a few times to improve the shuffle

### Aug 31, 2022
- Add namespace/prefix for session variables to avoid conflicts
- Rename org_name --> org_id
  * Organization Name --> Organization ID
  * Pairer.allowed_org_names --> Pairer.config.allowed_org_ids
  * pairer_boards.org_name --> pairer_boards.org_id
  * To upgrade from a previous version, add the following to your `config/initializers/pairer.rb`
    * `require Pairer.root.join("app/models/pairer/board"); ActiveRecord::Migration.new.rename_column(:pairer_boards, :org_name, :org_id) if Pairer::Board.column_names.include?("org_name")`
- Style improvements
- Add another button for "Add Group" below group list for more intuitive feel

### Aug 30, 2022
- Style improvements
- Hide person/role delete buttons within the groups section
- Remove data-confirm on group delete/sweep
- Change group delete icon to a broom/sweep icon
- Ensure stats do not contain bogus entries caused by re-shuffling, groups created less than 1 minute ago are deleted upon shuffle
- Extract sessions actions from MainController to SessionsController
- Rename MainController to BoardsController
- Remove "View Password" button, can use the view password feature within "Change Password" instead

### Aug 24, 2022
- Initial Release
