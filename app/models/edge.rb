class Edge < ActiveRecord::Base
  belongs_to :parent, class_name: "Requirement"
  belongs_to :child, class_name: "Requirement"
end
