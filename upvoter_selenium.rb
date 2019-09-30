require 'rubygems'
require 'capybara'
require 'capybara/rspec'
require 'phantomjs'
require 'deathbycaptcha'
require 'byebug'

class Upvoter
  def initialize
        
    Capybara.default_driver = :selenium
    Capybara.javascript_driver = :webkit
    Capybara.register_driver :chrome_headless do |app|
    end
    @session = Capybara::Session.new(:selenium)
    @urls = File.foreach(ARGV[0]).map{|line| line.chomp}
    @urls_for_check = []
    @users = File.foreach(ARGV[1]).map{|line| [:email, :password].zip(line.chomp.split).to_h}
    
    # SPECIFY UNIQUE TEXT HERE FOR SEARCH
    #####################################################################
    @string = ''
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
    @session.visit "https://www.banggood.com/login.html"
    @session.fill_in 'login-email', with: user[:email]
    @session.fill_in 'login-pwd', with: user[:password]
    @session.click_button('login-submit')
    sleep 1
    walkaround_captcha(user) if current_is_login
    puts 'Logged in'
  end

  def logout
    puts "Logging out"
    @session.visit "https://www.banggood.com/index.php?com=account&t=logout"
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
    @session.visit url+"#customerQA"
    sleep 1

    # start search
    begin
      # els = @session.all('.answerList.clearfix')
      els = @session.all(:xpath, './/div[@class="answerList clearfix"]')
      els.each do |el|
        el.find('.topBtn').click if el.find('.topBtn')
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