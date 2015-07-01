class Requirement < ActiveRecord::Base
  has_many :parent_edges, class_name: 'Edge', foreign_key: 'child_id', dependent: :destroy
  has_many :child_edges, class_name: 'Edge', foreign_key: 'parent_id', dependent: :destroy
  has_many :children, through: :child_edges
  has_many :parents, through: :parent_edges
  validates :name, presence: true

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

  def satisfy(student_set)
    if children.map(&:children).flatten.all? { |item| item.is_a? Course }
    end
  end

  def uplus(requirement)
    as, bs = uplus_child, requirement.uplus_child
    c =  (as & bs).map(&:hours).reduce(:+).to_i
    a = [(as - bs).map(&:hours).reduce(:+).to_i, hours].min
    b = [(bs - as).map(&:hours).reduce(:+).to_i, hours].min
    result = Requirement.new(hours: [a + b + c, hours + requirement.hours].min)
    result.uplus_child(as & bs)
    result
  end

  def uplus_child(x = nil)
    (@uplus_child ||= x) || children
  end

end
