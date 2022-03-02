require_relative '../views/views'
require_relative '../model/student'
require_relative '../model/slack_user'
require 'open-uri'
require 'net/http'
require 'json'
require 'nokogiri'

class Controller
  def initialize(repository)
    @repository = repository
    @view = View.new
  end

  def add(token, cookie)
    @repository.add(token, cookie)
  end

  def exist?
    @repository.exist?
  end

  def add_post_data!(post_body, name, data)
    boundary = "u3wUu37HQZispCXJ"
    post_body << "\r\n--#{boundary}\r\n"
    post_body << "Content-Disposition: form-data; name=\"#{name}\"\r\n"
    post_body << "\r\n"
    post_body << "#{data}"
  end

  def get_message
    boundary = "u3wUu37HQZispCXJ"
    post_body = []
    add_post_data!(post_body, "token", @repository.user.token)
    add_post_data!(post_body, "ignore_replies", "true")
    add_post_data!(post_body, "include_full_users", "true")
    add_post_data!(post_body, "include_use_case", "true")
    add_post_data!(post_body, "count", "28")
    add_post_data!(post_body, "channel", "C031S7YMLJC")
    uri = URI("https://lewagon-alumni.slack.com/api/conversations.view?_x_id=noversion-1646135422.362&_x_version_ts=noversion&_x_gantry=true&fp=3a")
    req = Net::HTTP.new(uri.host, uri.port)
    req.use_ssl = true
    post_request = Net::HTTP::Post.new uri
    post_request.body = post_body.join
    post_request["Content-Type"] = "multipart/form-data; boundary=#{boundary}"
    post_request["Cookie"] = "d=#{@repository.user.cookie}"
    response = req.request(post_request)
    all_mesages = JSON.parse(response.body)
    all_mesages["history"]["messages"].each do |message|
      msg = message["text"].match(/https:\/\/edusign.app\/..\/.{8}/)
      #puts msg
      return msg.to_s if msg != nil
    end
  end

  def get_students
    html = URI.open("https://api.edusign.fr/student/courses/code/#{get_message.split("/").last}", "User-Agent" => "Mozilla/5.0").read()
    json_response = JSON.parse(html)
    json_response["result"]["STUDENT_LIST"].each do |student|
      @repository.add_students(student["ID"], student["FIRSTNAME"], student["LASTNAME"])
    end
  end

  def get_absent_students
    html = URI.open("https://api.edusign.fr/student/courses/code/#{get_message.split("/").last}", "User-Agent" => "Mozilla/5.0").read()
    json_response = JSON.parse(html)
    json_response["result"]["STUDENTS"].each do |student|
      @repository.add_absent_student(@repository.find_student(student["studentId"])) if @repository.find_student(student["studentId"]) && student["state"] == false
    end
  end

  def get_slack_students
    uri = URI('https://edgeapi.slack.com/cache/T02NE0241/users/list?fp=3a')
    req = Net::HTTP.new(uri.host, uri.port)
    req.use_ssl = true
    post_request = Net::HTTP::Post.new(uri)
    post_request["Content-Type"] = "application/json"
    post_request["Cookie"] = "d=#{@repository.user.cookie}"
    post_request.body = {token: @repository.user.token,
                include_profile_only_users: false,
                count: 50,
                channels: ["C031S7YMLJC"], filter: "people",
                index: "users_by_display_name", locale: "en-US", present_first: false,
                fuzz: 1}.to_json
    response = req.request(post_request)
    json_response = JSON.parse(response.body)
    json_response["results"].each do |user|
      firstname, lastname = user["real_name"].split()
      @repository.add_slack_user(SlackUser.new({id: user["id"], firstname: firstname, lastname: lastname}))
    end
  end

  def send_message_to_absent_students
    # translate slack users to absent users
    slack_ids = []
    @repository.all_absent_students.size.times do |index|
      @repository.all_slack_users.each do |user|
        slack_ids << "{\"type\":\"user\",\"user_id\":\"#{@repository.all_slack_users.find { |user| user.lastname.upcase == @repository.all_absent_students[index].lastname.upcase}.id}\"}" if user.lastname.upcase == @repository.all_absent_students[index].lastname.upcase
      end
    end
    #p slack_ids
    boundary = "u3wUu37HQZispCXJ"
    post_body = []
    add_post_data!(post_body, "channel", "C031S7YMLJC")
    add_post_data!(post_body, "ts", "1646125951.xxxxx4")
    add_post_data!(post_body, "type", "message")
    add_post_data!(post_body, "xArgs", "{\"draft_id\":\"2871bad3-7c82-4201-937c-3746e831ff1f\"}")
    add_post_data!(post_body, "unfurl", "[]")
    add_post_data!(post_body, "blocks", "
      [{\"type\":\"rich_text\",\"elements\":[{\"type\":\"rich_text_section\",\"elements\":[#{slack_ids.join(",")},{\"type\":\"text\",\"text\":\"EduSign \"},{\"type\":\"emoji\",\"name\":\"lower_left_fountain_pen\"}]}]}]
      ")
    add_post_data!(post_body, "draft_id", "2871bad3-7c82-4201-937c-3746e831ff1c")
    add_post_data!(post_body, "include_channel_perm_error", "true")
    add_post_data!(post_body, "client_msg_id", "c1071360-cb1d-4d7d-91e4-62c4fe4da873x")
    add_post_data!(post_body, "token", "xoxc-2762002137-3087284867910-3099507653155-34927cf6c4d96e16085f58d8d7c7f6b2d6c4eba2a235d52a944042a3e8d1f48f")
    add_post_data!(post_body, "_x_reason", "webapp_message_send")
    add_post_data!(post_body, "_x_mode", "online")
    add_post_data!(post_body, "_x_sonic", "true")

    uri = URI("https://lewagon-alumni.slack.com/api/chat.postMessage?_x_id=edca1717-1646125951.976&_x_csid=i5Y5iPdWh5Q&slack_route=T02NE0241&_x_version_ts=1646105249&_x_gantry=true&fp=3a")
    req = Net::HTTP.new(uri.host, uri.port)
    req.use_ssl = true
    post_request = Net::HTTP::Post.new uri
    post_request.body = post_body.join
    post_request["Content-Type"] = "multipart/form-data; boundary=#{boundary}"
    post_request["Cookie"] = "d=#{@repository.user.cookie}"
    req.request(post_request)
    #edusign to slack user and seng message
  end
end
