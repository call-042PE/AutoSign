# model for slack user
class User
  attr_reader :token, :cookie

  def initialize(token, cookie)
    @token = token
    @cookie = cookie
  end
end
