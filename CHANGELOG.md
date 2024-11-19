# CHANGELOG

### Unreleased
- [View Diff](https://github.com/westonganger/pairer/compare/v1.1.0...master)
- [#17](https://github.com/westonganger/pairer/pull/17) - Remove dependency on Sprockets. Now compatible with both Propshaft and Sprockets.

### v1.1.0 - July 23, 2024
- [View Diff](https://github.com/westonganger/pairer/compare/v1.0.0...v1.1.0)
- [#16](https://github.com/westonganger/pairer/pull/16) - Improve board manipulation
- [#15](https://github.com/westonganger/pairer/pull/15) - Require Rails 6+ and Ruby 2.7+
- [#14](https://github.com/westonganger/pairer/pull/14) - Remove bootstrap-sprockets and sassc dependency
- [#12](https://github.com/westonganger/pairer/pull/12) - On boards#show page, if someone else makes changes to the board while you are simultaneously viewing the board, show javascript alert to reload the page. Implemented using ActionCable.
- [#11](https://github.com/westonganger/pairer/pull/11) - Do not automatically load migrations and instead require an explicit migration install step

### v1.0.0 - Oct 17, 2023
- Release to Rubygems

### Apr 1, 2023
- Move input for "Num Iterations to Track" to be inline with the stats description text

### Mar 29, 2023
- Remove unnecessary controller exception handling

### Feb 18, 2023
- Improve UX by disabling text selection when attempting to drag people/roles
- Fix javascript UI bug on sweep where it would duplicate roles
- Fix javascript UI bug on create person

### Feb 10, 2023
- Fix issue with dragging items within a group after lock/unlock

### Jan 6, 2023
- Revert: Update stats when groups have not changed in last hour

### Dec 6, 2022
- Update stats when groups have not changed in last hour
- Fix drag-and-drop after creating new group
- CSS fixes for smaller screen widths

### November 17, 2022
- Add "Recently Accessed Boards" stored in session variable

### November 11, 2022
- Improve highlighting for lock buttons on locked people and groups
- Change colors of sweep button
- Add missing Javascript DOM manipulations after "Sweep" action

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
