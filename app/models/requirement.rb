class Requirement < ActiveRecord::Base
  has_many :parent_edges, class_name: 'Edge', foreign_key: 'child_id', dependent: :destroy
  has_many :child_edges, class_name: 'Edge', foreign_key: 'parent_id', dependent: :destroy
  has_many :children, through: :child_edges
  has_many :parents, through: :parent_edges
  validates :name, presence: true

  attr_accessor :satisfied, :uplus_children

  def subtree
    { self => children.map(&:subtree) }
  end

  def named_subtree(width = nil)
    width ||= [children.count { |child| child.is_a? Requirement },10].max
    { name: name,
      children: (children.sample(width).map(&:named_subtree) << (
        { name: "+#{children.size - width } more" } if children.size > width)).compact 
    }
  end

  def satisfy(student_set, minimum_grade = 0)
    minimum_subs = take || children.size
    subreq = children.map{ |child| child.satisfy(student_set, min_grade) }.select(&:satisfied)
    subhours = subreq.reduce(Requirement.new(hours: 0), :uplus)
    subhours.satisfied = subreq.size >= minimum_subs.to_i && subhours.hours >= hours.to_i
    subhours.hours = hours
    subhours
  end

  def uplus(requirement)
    as, bs = uplus_children, requirement.uplus_children
    c =  (as & bs).map(&:hours).reduce(:+).to_i
    a = [(as - bs).map(&:hours).reduce(:+).to_i, hours].min
    b = [(bs - as).map(&:hours).reduce(:+).to_i, hours].min
    result = Requirement.new(hours: [a + b + c, hours.to_i + requirement.hours.to_i].min)
    result.uplus_children = as + bs
    result
  end

  def uplus_children
    @uplus_children || children
  end

end
