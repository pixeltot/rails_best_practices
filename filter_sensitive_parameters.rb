# Filtering Sensitive Parameters

# sometimes you may need to filter sensitive parameters
# such as a ssn, a cc, or a password
# here is how you can do that

# go to this directory: config\application.rb
# look for the config.filter_parameters option
config.filter_parameters += [:password, :ssn]
# here you can add and extra fields that need to be filtered from the logs
# if you wanted to add a credit_card number you can do this:
config.filter_parameters += [:password, :ssn, :credit_card]

# now when you look at the logs you will notice that the ssn, and credit_card fields are being filtered
# this sounds like a small detail, but its important, and people often forget about this


