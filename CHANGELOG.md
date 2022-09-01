# CHANGELOG

### Aug 31, 2022
- Add namespace/prefix for session variables to avoid conflicts
- Rename org_name --> org_id
  * Organization Name --> Organization ID
  * Pairer.allowed_org_names --> Pairer.allowed_org_ids
  * pairer_boards.org_name --> pairer_boards.org_id
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
