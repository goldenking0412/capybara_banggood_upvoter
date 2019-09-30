require 'rubygems'
require 'capybara'
require 'capybara/poltergeist'
require 'phantomjs'
#require 'DeathByCaptcha'
require 'deathbycaptcha'
require 'byebug'

class Amazon
	def initialize
		@dbc = DeathByCaptcha.new('Edgars74', '147963', :http)	

		Capybara.register_driver :selenium do |app|
			Capybara::Selenium::Driver.new(app)
		    # Capybara::Selenium::Driver.new(app, :browser => :chrome) # I used chrome
		end
		Capybara.javascript_driver = :selenium
		Capybara.default_selector = :css
		@session = Capybara::Session.new(:selenium)
		
	
		# here will be question users
		@question_users = [
		#	{email: 'hammond@getdll.com', password: '147963'},
		#	{email: 'grim@getdll.com', password: '147963'},
		#	{email: 'josh@getdll.com', password: '147963'},
		#	{email: 'Ralph@getdll.com', password: '147963'},
			{email: 'Rick@getdll.com', password: '147963'},
			{email: 'Pierre@getdll.com', password: '147963'},
			{email: 'William@getdll.com', password: '147963'},
			{email: 'Everett@getdll.com', password: '147963'},
			{email: 'Stephen@getdll.com', password: '147963'},
		#	{email: 'Leo@getdll.com', password: '147963'},
		#	{email: 'Thomas@getdll.com', password: '147963'},
		#	{email: 'Nicole@getdll.com', password: '147963'},
		#	{email: 'Kallie@getdll.com', password: '147963'},
		#	{email: 'Charles@getdll.com', password: '147963'},
		#	{email: 'Dwayne@getdll.com', password: '147963'},
		#	{email: 'Norman@getdll.com', password: '147963'},
		#	{email: 'Mallie@getdll.com', password: '147963'},
		#	{email: 'Alex@getdll.com', password: '147963'},
		#	{email: 'Vincent@getdll.com', password: '147963'},
		#	{email: 'Amanda@getdll.com', password: '147963'},
		#	{email: 'Michael@getdll.com', password: '147963'},
		#	{email: 'JosephK@getdll.com', password: '147963'},
		#	{email: 'Deborah@getdll.com', password: '147963'},
		#	{email: 'Althea@getdll.com', password: '147963'},
		#	{email: 'Tanya@getdll.com', password: '147963'},
		#	{email: 'Candida@getdll.com', password: '147963'},
		#	{email: 'AntonioA@getdll.com', password: '147963'},
		#	{email: 'MarilynA@getdll.com', password: '147963'},
		#	{email: 'FrancesM@getdll.com', password: '147963'},
		#	{email: 'KentLKaspar@armyspy.com', password: '147963'},
		#	{email: 'MarvinMKiefer@jourrapide.com', password: '147963'},
		#	{email: 'CarrieLMoore@teleworm.us', password: '147963'},
		#	{email: 'HelenCMelendez@dayrep.com', password: '147963'},
		#	{email: 'AlfonsoJLewis@armyspy.com', password: '147963'}


		]
		#below is for test
		#@question_users = [{email: 'FrancesM@getdll.com', password: '147963'}]
		@question_limit_per_user = 20
		@answer_user = {email: 'hanry@tincandroid.com', password: '147963'}
		@urls = File.foreach(ARGV[0]).map{|line| line.chomp}
		@upvote_users = File.foreach('users.txt').map{|line| [:email, :password].zip(line.chomp.split).to_h}
		@questions = []
		@succeed_urls = []
		@skipped_urls = []
		@phrases = ['phrase 1 xxx', 'phrase 2 xxx', 'phrase 1 xxx']
		@phrases2 = ['My phrase 1', 'My phrase 2', 'My phrase 3']
		@myquestions = ['Is it any good?', 'Is it any good2?']

		# SPECIFY UNIQUE TEXT HERE FOR SEARCH
		#####################################################################
		@string = 'xxx'
		#####################################################################

		puts 'Script initialized'


		post_questions
		sleep 1
		answer_questions
		sleep 1
		vote_questions
		sleep 1
		upvote_questions

		puts 'Internal done...'
	end

	def walkaround_captcha(user)
		puts 'Capthca is needed!'
		puts 'Running DeathByCaptcha:'
		@session.fill_in 'guess', with: "243"
		captcha = @dbc.decode(url: @session.find('img')[:src])
		captcha = captcha.text if captcha
		puts "Got answer #{captcha}"
		@session.fill_in 'email', with: user[:email]
		@session.fill_in 'password', with: user[:password]
		@session.fill_in 'guess', with: captcha
		@session.click_button('signInSubmit')
		sleep 1
		if current_is_login?
			puts 'Captcha failed!'
			walkaround_captcha(user)
		end
	end

	def walkaround_captcha2
		puts 'Question capthca is needed!'
		puts 'Running DeathByCaptcha:'
		@session.fill_in 'captchaGuess', with: "243"
		captcha = @dbc.decode(raw64: @session.find('img[id="captcha_image"]')[:src].sub('data:image/png;base64,', ''))
		captcha = captcha.text if captcha
		puts "Got answer #{captcha}"
		@session.fill_in 'captchaGuess', with: captcha
		sleep 2
		@session.find('input[type="image"]').click
		#@session.click_button('captcha_ces')
		sleep 1
		if current_is_captcha?
			puts 'Captcha failed!'
			walkaround_captcha2
		end
	end

	def current_is_login?
		@session.current_url.match(/amazon\.com\/ap\/signin/)
	end

	def current_is_captcha?
		@session.current_url.match(/amazon\.com\/gp\/forum\/update/)
	end

	def login(user)
		puts "Logging in #{user[:email]}" 
		debugger
		@session.visit "https://www.amazon.com/ap/signin?_encoding=UTF8&openid.assoc_handle=usflex&openid.claimed_id=http%3A%2F%2Fspecs.openid.net%2Fauth%2F2.0%2Fidentifier_select&openid.identity=http%3A%2F%2Fspecs.openid.net%2Fauth%2F2.0%2Fidentifier_select&openid.mode=checkid_setup&openid.ns=http%3A%2F%2Fspecs.openid.net%2Fauth%2F2.0&openid.ns.pape=http%3A%2F%2Fspecs.openid.net%2Fextensions%2Fpape%2F1.0&openid.pape.max_auth_age=0&openid.return_to=https%3A%2F%2Fwww.amazon.com%3Fie%3DUTF8%26ref_%3Dnav_ya_signin"
		@session.fill_in 'email', with: user[:email]
		@session.fill_in 'password', with: user[:password]
		@session.click_button('signInSubmit')
		puts 'Submiting form...'
		sleep 1
		walkaround_captcha(user) if current_is_login?
		puts 'Logged in'
	end

	def logout
		puts "Logging out"
		@session.visit "https://www.amazon.com/gp/flex/sign-out.html/ref=nav_youraccount_signout?ie=UTF8&action=sign-out&path=%2Fgp%2Fyourstore%2Fhome&signIn=1&useRedirectOnSuccess=1"
		puts 'Logged out'
	end

	def post_questions
		puts 'Start posting questions...'

		user_index = 0
		url_index = 0

		loop do 
		  login(@question_users[user_index])
		  puts "Preparing to post #{@question_limit_per_user} questions..."
		  @question_limit_per_user.times do
		  	if @urls[url_index]
			  	post_question(@urls[url_index], @question_users[user_index])
			  	url_index += 1
				end
		  end
		  puts "Posted #{@question_limit_per_user} questions, will change user now..."
		  logout
		  user_index = user_index + 1 < @question_users.size ? user_index + 1 : 0 # next or first again
		  break if @urls.size == url_index
		end

		puts 'All questions are posted!'
	end

	def post_question(url, user)
		sleep 1
		puts "Product url -- #{url}"
		@session.visit url

	if @session.has_text?('xxx')
	
puts "Already posted here. Skipping!"

	else

		if @session.all('input[name="askQuestionText"]').any?
			infos = @session.all('div[id^="question-"]').map do |question|
			asnwer_spanned = nil
			answer_container = question.first(:xpath, 'ancestor::div[@class="a-fixed-left-grid-col a-col-right"]')
								.find('.a-fixed-left-grid.a-spacing-base')
								.find('.a-fixed-left-grid-col.a-col-right')
			begin
				answer = if ((answer_container.first('span')[:class]) || '').split.include? 'askExpanderContainer'
					answer_container.find('.askShortText').first('a').click
					asnwer_spanned = answer_container.find('.askLongText').text
					answer_container.find('.askLongText').native['innerHTML'].strip.match(/(.+)/).to_s.gsub('<br>', "\n")
				else
					answer_container.first('span').text
				end
			rescue
				answer = nil
			end
			{
				question: question.find('a').text,
				answer: (answer if answer),
				spanned_answer: (asnwer_spanned if asnwer_spanned)
			}
			end.select{|q|q[:answer]}

			puts "Found #{infos.count} questions with answers"
			if info = infos.sample
				puts 'Randomly chosen'
				puts "Question: #{info[:question]}"
				puts "Answer: #{info[:answer]}"

				sleep 1
				@session.fill_in 'askQuestionText', with: info[:question]
				@session.click_button('Ask the Community')
				sleep 1

				if (@session.current_url == url) || current_is_login?
					@skipped_urls << url
					#@urls.delete_if {|u| u == url}
					puts 'Error occured while asking question. Skipped this question...'
					#$stdin.gets
					File.open('skipped_urls.txt', 'a+') do |f|
						f.write("#{url}\n")
					end
					puts 'Url is written to file'
				else
					if @session.all('div[class="a-box a-alert-success"]').empty?
						# NOT OK!!!
						@skipped_urls << url
						puts 'For some reason question was not asked. Skipped this question...'
						File.open('skipped_urls.txt', 'a+') do |f|
							f.write("#{url}\n")
						end
						puts 'Url is written to file'
					else
						# OK!
						@questions << info.merge({url: @session.current_url, product_url: url, user: user})
						@succeed_urls << url
						puts "Successfully asked question, url: #{@session.current_url}"
						File.open('succeed_urls.txt', 'a+') do |f|
							f.write("#{url}\n")
						end
					end
					puts 'Url is written to file'
				end
			else
				# if no questions was there, ask your own
				info2 = "#{@myquestions.sample}"
				answer2 = "#{@phrases2.sample}"

				puts 'Using my own question...'
				puts "Question: #{info2}"
				puts "Answer: #{answer2}"
				
				@session.fill_in 'askQuestionText', with: info2
				@session.click_button('Ask the Community')
				sleep 1
				if @session.all('div[class="a-box a-alert-success"]').empty?
					# NOT OK!!!
					@skipped_urls << url
					puts 'For some reason question was not asked. Skipped this question...'
					File.open('skipped_urls.txt', 'a+') do |f|
						f.write("#{url}\n")
					end
				else
					# OK!
					@succeed_urls << url
					@questions << {question: info2, answer: answer2, url: @session.current_url, product_url: url, user: user}
					puts "Successfully asked question, url: #{@session.current_url}"
					File.open('succeed_urls.txt', 'a+') do |f|
						f.write("#{url}\n")
					end
				end
				puts 'Url is written to file'
				puts "Skipped this question..."
			end
		else
			puts 'No product found on this url'
			@skipped_urls << url
			File.open('skipped_urls.txt', 'a+') do |f|
						f.write("#{url}\n")
					end
		end

end		
	rescue Capybara::Poltergeist::StatusFailError
		@skipped_urls << url
		File.open('skipped_urls.txt', 'a+') do |f|
						f.write("#{url}\n")
					end
		puts "Error with accessing #{url}"
		puts "Skipped this question..."
	end

	def answer_questions
		puts "Answering #{@questions.size} questions..."
		login(@answer_user)
		@questions.each {|question| answer_question(question)}
		logout
	end

	def answer_question(question)
		puts "Answering #{question[:url]}"
		puts "Question: #{question[:question]}"
		puts "Original answer: #{question[:answer]}"
		dot = '.' unless question[:answer][-1].match(/\?|!|\.|\,|;/)
		question[:answer] = "#{question[:answer]}#{dot} #{@phrases.sample}"
		puts "Unique answer: #{question[:answer]}"
		@session.visit question[:url]
		sleep 1
		@session.fill_in 'bodyText', with: question[:answer]
		@session.click_button('Answer')
		sleep 1
		walkaround_captcha2 if current_is_captcha?
		puts 'Answered!'
		sleep 9

	rescue
		puts 'rescuing script'
		#@skipped_urls << question[:product_url]
		#@succeed_urls.delete_if {|u| u == question[:product_url]}
		#File.open('answer_failed_urls.txt', 'a+') do |f|
		#	f.write("#{url}\n")
		#end
		#puts 'Written url to file'
		#@questions.delete_if {|q| q[:product_url] == question[:product_url]}
		puts 'Unable to find question. written this url to file with answer faults...'
		
	end

	def vote_questions
		puts "Starting to vote for answers by question users..."
		@question_users.each do |question_user|
			login(question_user)
			questions = @questions.select {|question| question[:user] == question_user}
			puts "Found #{questions.size} by #{question_user[:email]}"
			questions.each {|question| vote_question(question)}
			puts "Upvoted questions by #{question_user[:email]}"
			logout
		end
		puts 'Answers voted by question users!'
	end

	def vote_question(question)
		sleep 1
		puts "Voting answer on #{question[:url]}"
		@session.visit question[:url]
		@session.all('.cdMessageInfo').first do |element|
			element.first('span').text == question[:answer]
		end.find('.yesButton').click
		puts 'voted!'
	rescue
		puts "Cannot upvote #{question[:url]}"
		sleep 1
	end

	def upvote_questions
		puts 'Upvoting questions'
		@upvote_users.each do |user|
			login(user)
			@succeed_urls.each {|url| upvote_question(url)}
			logout
			sleep 1
		end
	end

	def upvote_question(url)
		puts "Upvoting -- #{url}"

		# click more on all
		@session.visit url
		sleep 1
		@session.all('div[id^="question-"]').each do |question|
			answer_container = question.first(:xpath, 'ancestor::div[@class="a-fixed-left-grid-col a-col-right"]')
								.find('.a-fixed-left-grid.a-spacing-base')
								.find('.a-fixed-left-grid-col.a-col-right')
			if answer_container.first('span')
				answer = if (answer_container.first('span')[:class] || '').split.include? 'askExpanderContainer'
					answer_container.find('.askShortText').first('a').click
				end
			end
		end
		puts 'Opened all collapsed answers'
		sleep 1

		# start search
		begin
			puts "Upvoting by unique text: #{@string}"
			els = @session.first('span', text: Regexp.new(@string))
					.all(:xpath, 'ancestor::div[@class="a-fixed-left-grid a-spacing-base"]')
			els.each do |el|
				el.find('.vote.voteAjax').find('input[value="Vote Up"]').click if el.first('.vote.voteAjax')
				sleep 1
			end	
			puts "Upvoted! OK!"
		rescue
			puts 'This page doesn\'t have necessary text. Added to file.'
			File.open('not_upvoted_urls.txt', 'a+') do |f|
				f.write("#{url}\n")
			end
		ensure
			sleep 1
		end
	end
end

# usage
robot = Amazon.new
puts 'Done!'
