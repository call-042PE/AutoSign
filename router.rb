class Router
  def initialize(controller)
    @controller = controller
    @running = true
  end

  def run
    puts "EduSign reminder"
    puts "           --           "
    if !@controller.exist?
      puts "What is your user token?"
      token = gets.chomp
      puts "What is your cookie?"
      cookie = gets.chomp
      @controller.add(token, cookie)
    end
    @controller.get_students
    @controller.get_absent_students
    @controller.get_slack_students
    @controller.send_message_to_absent_students
  end
end

# get token user
# get cookie user
# check message with regex and getting link
# check with scrapping the edusign link and get those who don't signed
# send message to them
