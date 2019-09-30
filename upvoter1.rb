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
		    Capybara::Poltergeist::Driver.new(app, debug: false)
		end
		Capybara.default_selector = :css
		@session = Capybara::Session.new(:poltergeist)
		@session.driver.headers = { 'User-Agent' =>
			"Mozilla/5.0 (Macintosh; Intel Mac OS X)" }
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
		@session.current_url.match(/amazon\.com\/ap\/signin/)
	end

	def login(user)
		puts "Logging in #{user[:email]}"
		debugger
		@session.visit "https://www.amazon.com/ap/signin?_encoding=UTF8&openid.assoc_handle=usflex&openid.claimed_id=http%3A%2F%2Fspecs.openid.net%2Fauth%2F2.0%2Fidentifier_select&openid.identity=http%3A%2F%2Fspecs.openid.net%2Fauth%2F2.0%2Fidentifier_select&openid.mode=checkid_setup&openid.ns=http%3A%2F%2Fspecs.openid.net%2Fauth%2F2.0&openid.ns.pape=http%3A%2F%2Fspecs.openid.net%2Fextensions%2Fpape%2F1.0&openid.pape.max_auth_age=0&openid.return_to=https%3A%2F%2Fwww.amazon.com%3Fie%3DUTF8%26ref_%3Dnav_ya_signin"
		@session.fill_in 'email', with: user[:email]
		@session.fill_in 'password', with: user[:password]
		@session.click_button('signInSubmit')
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