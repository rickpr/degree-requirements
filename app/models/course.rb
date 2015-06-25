class Course < Requirement
  validates :min_grade, absence: true
  validates :take, absence: true
  # This is the base case and should return self
  def subtree
    self
  end

  def named_subtree
    { name: name }
  end

end
