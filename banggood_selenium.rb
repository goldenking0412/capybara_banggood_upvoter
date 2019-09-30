require 'rubygems'
require 'capybara'
require 'capybara/rspec'
require 'phantomjs'
require 'deathbycaptcha'
require 'byebug'

class Amazon
  def initialize
    @dbc = DeathByCaptcha.new('Edgars74', '147963', :http)  

    Capybara.javascript_driver = :selenium
    @session = Capybara::Session.new(:selenium)
    
    # user credentials
    # here will be question users
    @question_users = [
      # {email: 'Rick@getdll.com', password: '147963'},
      {email: 'Pierre@getdll.com', password: '147963'},
      {email: 'William@getdll.com', password: '147963'},
      {email: 'Everett@getdll.com', password: '147963'},
      {email: 'Stephen@getdll.com', password: '147963'},
    ]
    @answer_user = {email: 'ozols74@gmail.com', password: '147963'}
    @upvote_users = File.foreach('users.txt').map{|line| [:email, :password].zip(line.chomp.split).to_h}

    #below is for test
    @question_limit_per_user = 20
    @urls = File.foreach(ARGV[0]).map{|line| line.chomp}
    @questions = []
    @succeed_urls = []
    @skipped_urls = []
    @success_question_urls = []
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
    begin 
      @session.find('.header-user-signBtn')
      return true;
    rescue
      return false;
    end
    return false;
    # @session.current_url.match(/amazon\.com\/ap\/signin/)
  end

  def current_is_captcha?
    @session.current_url.match(/amazon\.com\/gp\/forum\/update/)
  end

  def login(user)
    puts "Logging in #{user[:email]}" 
    @session.visit "https://www.banggood.com/login.html"
    # debugger
    @session.fill_in 'login-email', with: user[:email]
    @session.fill_in 'login-pwd', with: user[:password]
    @session.click_button('login-submit')
    puts 'Submiting form...'
    sleep 1
    walkaround_captcha(user) if current_is_login?
    puts 'Logged in'
  end

  def logout
    puts "Logging out"
    @session.visit "https://www.banggood.com/index.php?com=account&t=logout"
    # debugger
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
      debugger
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
    @session.visit url + '#customerQA'
    sleep 3

    if @session.has_text?('xxx')
      puts "Already posted here. Skipping!"
    else

      if @session.all('input[name="question_content"]').any?
        infos = @session.all('span[class="ask_1"]').map do |question|
          asnwer_spanned = nil
          answer_container = question.first(:xpath, 'ancestor::div[@class="answerList_right"]')
                    .find('.answer_1')
          begin
            answer = answer_container.find('.answer_text_1').text if answer_container.find('.answer_text_1')
          rescue
            answer = nil
          end
          {
            question: question.find('a').find('em').text,
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
          @session.fill_in 'question_content', with: info[:question]
          @session.find('.qa_lead_new').click

          @session.find('.ask_submit').click
          sleep 1

          if @session.find('p[class="ask_return_alert"]').text != "Your question was successfully posted."
            # NOT OK!!!
            @skipped_urls << url
            puts 'For some reason question was not asked. Skipped this question...'
            File.open('skipped_urls.txt', 'a+') do |f|
              f.write("#{url}\n")
            end
          else
            @succeed_urls << url
            @session.find('.ask_return_link').click
            puts 'question url: '+@session.current_url
            @success_question_urls << @session.current_url

            answer_url = @session.current_url.sub! 'question-info', 'answer'
            answer_url = answer_url.sub! '.html', '-1.html'
            puts 'answer url: '+answer_url
            @questions << info.merge({url: @session.current_url, product_url: url, user: user, answer_url: answer_url})
            puts "Successfully asked question, url: #{@session.current_url}"
            File.open('succeed_urls.txt', 'a+') do |f|
              f.write("#{url}\n")
            end
          end

        else
          # if no questions was there, ask your own
          info2 = "#{@myquestions.sample}"
          answer2 = "#{@phrases2.sample}"

          puts 'Using my own question...'
          puts 'Question: #{info2}'
          puts 'Answer: #{answer2}'
          
          @session.fill_in 'question_content', with: info2
          @session.find('.qa_lead_new').click
          @session.find('.ask_submit').click
          sleep 1
          if @session.find('p[class="ask_return_alert"]').text != "Your question was successfully posted."
            # NOT OK!!!
            @skipped_urls << url
            puts 'For some reason question was not asked. Skipped this question...'
            File.open('skipped_urls.txt', 'a+') do |f|
              f.write("#{url}\n")
            end
          else
            # OK!
            @succeed_urls << @session.current_url
            @session.find('.ask_return_link').click
            puts "question url: "+@session.current_url
            @success_question_urls << @session.current_url

            answer_url = @session.current_url.sub! 'question-info', 'answer'
            answer_url = answer_url.sub! '.html', '-1.html'
            puts "answer url: "+answer_url
            @questions << {question: info2, answer: answer2, url: @session.current_url, product_url: url, user: user, answer_url: answer_url}
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
    # debugger
    puts "Unique answer: #{question[:answer]}"

    puts question[:answer_url]
    @session.visit question[:answer_url]
    sleep 1
    @session.fill_in 'answer_content', with: question[:answer]
    @session.find('span.submit-btn.js-submit-btn > a').click
    sleep 1
    walkaround_captcha2 if current_is_captcha?
    puts 'Answered!'
    sleep 9

  rescue
    puts 'rescuing script'
    #@skipped_urls << question[:product_url]
    #@succeed_urls.delete_if {|u| u == question[:product_url]}
    #File.open('answer_failed_urls.txt', 'a+') do |f|
    # f.write("#{url}\n")
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
      puts "voted questions by #{question_user[:email]}"
      logout
    end
    puts 'Answers voted by question users!'
  end

  def vote_question(question)
    puts "Voting answer on #{question[:answer_url]}"
    @session.visit question[:answer_url]
    sleep 3
    @session.all('.answers-bd-list') do |element|
      answer = element.find('span.answers-list-text').text
      debugger
      if question[:answer] == answer
        debugger
        element.find('.yes').click
      end
    end
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
    @session.visit url+'#customerQA'
    # debugger
    sleep 1
    @session.all('.answerList').each do |question|
      # debugger
      answer_container = question.find('.answer_text')
      begin
        debugger
        answer = answer_container.find('.answer_text_1').text
        if answer.include? "xxx"
          leftpart = question.find('.answerList_left')
          leftpart.find('.topBtn').click
        end
      rescue
        answer = nil
      end
    end
    sleep 1

    # start search
    # begin
    #   puts "Upvoting by unique text: #{@string}"
    #   debugger
    #   els = @session.first('div', text: Regexp.new(@string))
    #       .all(:xpath, '//div[contains(@class, "answerList") and contains(@class, "clearfix")]')
    #   els.each do |el|
    #     el.find('.topBtn').click if el.find('.topBtn')
    #     sleep 1
    #   end 
    #   puts "Upvoted! OK!"
    # rescue
    #   puts 'This page doesn\'t have necessary text. Added to file.'
    #   File.open('not_upvoted_urls.txt', 'a+') do |f|
    #     f.write("#{url}\n")
    #   end
    # ensure
    #   sleep 1
    # end
  end
end

# usage
robot = Amazon.new
puts 'Done!'
