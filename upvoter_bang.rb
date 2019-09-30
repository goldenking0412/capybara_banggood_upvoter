require 'rubygems'
require 'capybara'
require 'capybara/poltergeist'
require 'phantomjs'
require 'deathbycaptcha'
require 'byebug'

class Upvoter
	def initialize
		@dbc = DeathByCaptcha.new('Edgars74', '147963', :http)
		
		Capybara.register_driver :poltergeist do |app|
		    Capybara::Poltergeist::Driver.new(app, {
		    	debug: false,
		    	timeout: 30,
		    	phantomjs_options: [
		    		'--web-security=false',
		    		'--ssl-protocol=any',
		    		'--debug=false'
		    	]})
		end
		Capybara.app_host = "https://www.banggood.com"
		Capybara.default_selector = :id
		# Capybara.javascript_driver = :selenium
		@session = Capybara::Session.new(:poltergeist)
		# @session.driver.headers = { 'User-Agent' =>
			# "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.103 Safari/537.36"}
		@session.driver.headers = { 'User-Agent' => "Poltergeist"}
		@session.driver.clear_cookies
		@urls = File.foreach(ARGV[0]).map{|line| line.chomp}
		@urls_for_check = []
		@users = File.foreach(ARGV[1]).map{|line| [:email, :password].zip(line.chomp.split).to_h}
		
		# SPECIFY UNIQUE TEXT HERE FOR SEARCH
		#####################################################################
		@string = 'xxx'
		#####################################################################
		
		puts 'Script initialized'

		upvote_questions

		if @urls_for_check.any?
			File.open('not_upvoted_urls.txt', 'a+') do |f|
				@urls_for_check.each do |url|
					f.write("#{url}\n")
				end
			end
		end
	end

	def walkaround_captcha(user)
		puts 'Capthca is needed!'
		puts 'Running DeathByCaptcha:'
		captcha = @dbc.decode(url: @session.find('img')[:src])
		captcha = captcha.text if captcha
		puts "Got answer #{captcha}"
		@session.fill_in 'email', with: user[:email]
		@session.fill_in 'password', with: user[:password]
		@session.fill_in 'guess', with: captcha
		@session.click_button('signInSubmit')
		sleep 1
		if current_is_login
			puts 'Captcha failed!'
			walkaround_captcha(user)
		end
	end

	def current_is_login
		puts 'lol'
		puts @session.current_url
		puts 'lol'
		@session.current_url.match(/banggood\.com\/ap\/signin/)
	end

	def login(user)
		puts "Logging in #{user[:email]}"
		debugger
		@session.visit "https://www.banggood.com/login.html"
		@session.fill_in 'login-pwd', with: user[:password]
		@session.fill_in 'login-email', with: user[:email]
		@session.click_button('login-submit')
		sleep 1
		walkaround_captcha(user) if current_is_login
		puts 'Logged in'
	end

	def logout
		puts "Logging out"
		@session.visit "https://www.amazon.com/gp/flex/sign-out.html/ref=nav_youraccount_signout?ie=UTF8&action=sign-out&path=%2Fgp%2Fyourstore%2Fhome&signIn=1&useRedirectOnSuccess=1"
		puts 'Logged out'
	end

	def upvote_questions
		puts 'Upvoting questions'
		@users.each do |user|
			login(user)
			@urls.each {|url| upvote_question(url)}
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
			@urls_for_check << url unless @urls_for_check.include? url
		ensure
			sleep 3
		end
	end

end

robot = Upvoter.new