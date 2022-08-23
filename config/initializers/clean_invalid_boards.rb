### CURRENTLY DISABLED
### Figured it might be better to manually delete, just in case any manual data migration needs to be done

#Rails.application.configure do

#  config.after_initialize do
#    job = Pairer::CleanupBoardsJob

#    job.perform_now
#    #job.set(wait: 1.minute).perform_later
#  end

#end
