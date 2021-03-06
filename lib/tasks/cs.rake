require 'cs_api_account'
require 'cs_api_challenge'
require 'cs_api_member'
require 'cs_api_community'
require 'sfdc_connection'
require 'open-uri'
require 'csv' 

desc "Returns a salesforce.com access token for the current environment"
task :get_access_token => :environment do
	# log in for an access token
	config = YAML.load_file(File.join(::Rails.root, 'config', 'databasedotcom.yml'))
	client = Databasedotcom::Client.new(config)
	access_token = client.authenticate :username => ENV['SFDC_USERNAME'], :password => ENV['SFDC_PASSWORD']  
	puts "Access token for #{ENV['DATABASEDOTCOM_HOST']}: #{access_token}"
end

desc "Refreshes the settting table with a new access token"
task :refresh_settings_access_token => :environment do
	config = YAML.load_file(File.join(::Rails.root, 'config', 'databasedotcom.yml'))
	client = Databasedotcom::Client.new(config)
	access_token = client.authenticate :username => ENV['SFDC_USERNAME'], :password => ENV['SFDC_PASSWORD'] 
	# delete the current record
	p Settings.delete(Settings.first)
	# save the new token
	s = Settings.new
	s.access_token = access_token
	s.save
	puts "Token refreshed and written to pg - #{access_token}"
end

desc "Deletes all users from PG and logs everyone off the site"
task :log_out_users => :environment do
	User.delete_all
	puts "All users logged out of the site"
end

desc "Send an 'invite' email to jeffdonthemic"
task :send_invite => :environment do
	Resque.enqueue(InviteEmailSender, 'jeffdonthemic', 'jeff@appirio.com')
	puts "Email sent!!"
end

desc "Send the 'import invite' email"
task :send_invite_from_import => :environment do
	access_token = SfdcConnection.public_access_token
	Resque.enqueue(WelcomeEmailFromImportSender, access_token, 'sample-membername', 'jeff@appirio.com', 
		'mypassword123', "Super-Duper Site Welcomes you to CloudSpokes", 'Super-Duper', 'appirio')
	puts "Email sent!!"
end

desc "Pick sweepstakes winners -- bundle exec rake pick_sweepstakes_winners[1907]"
task :pick_sweepstakes_winners, :challenge_id do |t, args|
	participants = HTTParty.get("https://api.cloudspokes.com/v1/challenges/#{args.challenge_id}/participants")['response']
	puts "#{participants.count} participants"
	puts "First place: #{participants[rand(participants.count)]['member__r']['name']}"
	puts "Second place: #{participants[rand(participants.count)]['member__r']['name']}"
end
=begin
desc "import imports csv file into import_members table"
task :import_members_csv, :url, :needs => :environment do |t, args|	

	csv = CSV.parse(open(args.url), :headers => true)
	csv.each do |row|
	  row = row.to_hash.with_indifferent_access
	  ImportMember.create!(row.to_hash.symbolize_keys)
	end
	puts "Done!"

end

desc "Reads members from pg and creates them in sfdc"
task :import_members, :partner_name, :limit, :community_id, :randomize, :needs => :environment do |t, args|

	Rails.logger.info "[IMPORT]Starting member import. Limit #{args.limit}. Partner #{args.partner_name}"

	access_token = SfdcConnection.public_access_token

	ImportMember.where("sfdc_username is null").limit(args.limit).each do |m|

		begin

			# create the membername from the first part of the email
			membername = m.email.slice(0,m.email.index('@'))
			plain_text_password = (0...6).map{65.+(rand(26)).chr}.join+rand(99).to_s
			if args.randomize
				membername << rand(99).to_s
				Rails.logger.info "[IMPORT]Randomizing membername to overcome dupes. New membername: #{membername}"
			end

			# make the username safe to only contain letters, numbers and underscores
			# replace - wiht _
			membername.gsub!(/-/,'_') if membername.include?('-')
			# replace all non letters, number and underscores
			membername.gsub!(/\W/,'')

			# create the member in sfdc
			results = CsApi::Account.create(access_token, 
				{:username => membername, :password => plain_text_password, :email => m.email}).symbolize_keys!

			if results[:success].eql?('true')

				Rails.logger.info "[IMPORT]Creating new SFDC member for #{membername}: #{results}"

				# update the import member with the sfdc username and temp password
				m.sfdc_username = results[:sfdc_username]
				m.membername = membername
				m.temp_password = Encryptinator.encrypt_string(plain_text_password)
				m.save

				# update with some data
				update_results = CsApi::Member.update(access_token, membername, {'school__c' => m.school, 
					'campaign_medium__c' => m.campaign_medium, 'campaign_name__c' => m.campaign_name, 
					'campaign_source__c' => m.campaign_source, 'first_name__c' => m.first_name, 
					'last_name__c' => m.last_name}).symbolize_keys!

				Rails.logger.info "[IMPORT][FATAL]Updating member #{membername}: #{update_results}" if update_results[:success].eql?('false')

			  # add the member to the community
			  unless args.community_id.eql?('none')
			  	add_member_results = CsApi::Community.add_member(access_token, {:membername => membername, :community_id => args.community_id})
					Rails.logger.info "[IMPORT]Adding member to community: #{add_member_results}"
				end

			  # send the 'welcome' email
			  Resque.enqueue(WelcomeEmailFromImportSender, access_token, membername, m.email, plain_text_password, "#{args.partner_name} Welcomes you to CloudSpokes", args.partner_name, args.community_id) unless ENV['MAILER_ENABLED'].eql?('false')
			  # add the user to badgeville
			  Resque.enqueue(NewBadgeVilleUser, access_token, membername, results[:sfdc_username]) unless ENV['BADGEVILLE_ENABLED'].eql?('false')		
			  
			  # disable the user for license purposes
			  CsApi::Account.disable(membername)

			  sleep(2)

			# coud not create member in salesforce
			else
				m.error_message = results[:message]
				m.save
				Rails.logger.info "[IMPORT][FATAL]Could not create sfdc user for #{membername}: #{results[:message]}"
			end

    rescue Exception => exc
      Rails.logger.info "[IMPORT][FATAL] #{exc.message}"
    end		

	end	

	puts "[IMPORT]Member import finished!"
	Rails.logger.info "[IMPORT]Member import finished!"

end
=end	