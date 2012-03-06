require 'cloud_spokes'

class QuickQuizes < Cloudspokes
  
  def self.fetch_10_questions(type=nil)
    if type.nil?
      get(ENV['QUICK_QUIZ_QUESTIONS_URL']+'/random.json')
    else
      get("#{ENV['QUICK_QUIZ_QUESTIONS_URL']}/random.json/#{type}")
    end
  end
  
  def self.save_answer(access_token, username, params)
    set_header_token(access_token)
    
    # PUT with the answer
    if params.has_key?('answer')
      put(ENV['SFDC_REST_API_URL']+"/quickquiz?quick_quiz_question__c=#{esc params['question_id']}&username=#{esc username}&answer__c=#{esc params['answer']}&is_correct__c=#{params['correct']}")
    
    # POST the username and question to start the timer
    else
      options = {
        :body => {
            :username => username,
            :quick_quiz_question__c => params['question_id']
        }
      }
      post(ENV['SFDC_REST_API_URL']+'/quickquiz', options)
    end
  end
  
  def self.find_answer_by_id(access_token, id)
    set_header_token(access_token)
    get(ENV['SFDC_REST_API_URL']+"/quickquiz?questionId=#{id}")
  end
  
  def self.winners_today(access_token)
    set_header_token(access_token)
    get(ENV['SFDC_REST_API_URL']+"/quickquiz/results/today")
  end
  
  def self.winners_last7days(access_token)
    set_header_token(access_token)
    get(ENV['SFDC_REST_API_URL']+"/quickquiz/results/last7days")
  end
  
  def self.winners_alltime(access_token)
    set_header_token(access_token)
    get(ENV['SFDC_REST_API_URL']+"/quickquiz/results/alltime")
  end
  
  def self.member_status_today(access_token, username)
    set_header_token(access_token)
    get(ENV['SFDC_REST_API_URL']+"/quickquiz/member/#{esc username}")
  end

end


   