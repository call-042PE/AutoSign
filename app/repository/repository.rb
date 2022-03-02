require 'json'
require_relative '../model/user'
class Repository
  attr_reader :user
  def initialize(json_file)
    @json_file = json_file
    @user = nil
    @students = []
    @absent_students = []
    @slack_users = []
    load_json
  end

  def add(token, cookie)
    @user = User.new(token, cookie)
    save_json
  end

  def add_students(id, firstname, lastname)
    @students << Student.new(id: id, firstname: firstname, lastname: lastname)
  end

  def add_absent_student(student)
    @absent_students << student
  end

  def add_slack_user(slack_user)
    @slack_users << slack_user
  end

  def all_students
    @students
  end

  def all_absent_students
    @absent_students
  end

  def all_slack_users
    @slack_users
  end

  def load_json
    if File.exist?(@json_file)
      file_content = File.read(@json_file)
      if file_content != ""
        user = JSON.parse(file_content)
        @user = User.new(user["token"], user["cookie"])
      end
    end
  end

  def find_student(id)
    @students.find { |student| student.id == id }
  end

  def save_json
    user = {token: @user.token, cookie: @user.cookie}
    File.open(@json_file, "wb") do |file|
      file.write(JSON.generate(user))
    end
  end

  def exist?
    @user == nil ? false : true
  end
end
