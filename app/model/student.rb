class Student
  attr_reader :id, :firstname, :lastname
  def initialize(arguments = {})
    @id = arguments[:id]
    @firstname = arguments[:firstname]
    @lastname = arguments[:lastname]
  end
end
