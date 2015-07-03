class Course < Requirement
  validates :min_grade, absence: true
  validates :take, absence: true

  attr_accessor :grade

  # This is the base case and should return self
  def subtree
    self
  end

  def named_subtree
    { name: name }
  end

  def satisfy(student_set, minimum_grade)
    course = student_set.find { |course| course.name == name }
    @satisfied = course && course.grade >= grade_to_i(minimum_grade)
    self
  end

  def grade_to_i(grade)
    grade_hash = Hash.new(0)
    grade_hash.merge(
      ["CR", "D-", "D", "D+", "C-", "C", "C+", "B-", "B", "B+", "A-", "A", "A+" ].map.with_index(1) { |grade, integer| { grade => integer } }.reduce(:merge))
    grade_hash[grade]
  end

end
