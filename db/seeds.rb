Dir.chdir Rails.root.join 'preprocess'

# Procedures
def to_req(req)
  to_r = req.reject { |x| x["courses"] }
  to_r.map{ |k,v| k == "credits" ? ["hours", v] : [k,v] }.to_h
end

def course_edges(parent, courses)
  courses.each do |course|
    Edge.create(parent_id: parent.id, child_id: Course.find_by_name(course).id)
  end
end

add_requirement = proc do |req|
  this = Requirement.create(to_req(req))
  course_edges(this, req["courses"])
  this
end

add_link = proc { |big_node, nodes| nodes.each { |node| Edge.create(parent_id: big_node.id, child_id: node.id) } }

add_course = proc { |course| course.each { |name, hours| Course.create name: name, hours: hours } }

from_json = proc { |file| JSON.parse File.read(file) }

# Courses file

course_files = Dir.glob('courses/*')
courses = course_files.flat_map &from_json 


# Requirements Files

requirements_files = Dir.glob('requirements/*') 

big_requirements = requirements_files.map { |file| File.basename(file, ".*").titleize }
requirements     = requirements_files.map &from_json 

# Programs Files
programs_files = Dir.glob('programs/*')

program_titles = programs_files.map { |file| File.basename(file, ".*").titleize }
programs       = programs_files.map &from_json

# Edges files

edge_files = Dir.glob('edges/*')

edges = edge_files.flat_map(&from_json).flat_map &:to_a

# The actual seeding

# Add courses
ActiveRecord::Base.transaction do
  courses.each &add_course

  # Add the upper nodes
  big_nodes = big_requirements.map { |big_node| Requirement.create(name: big_node) } 
  big_nodes += program_titles.map { |big_node| Program.create(name: big_node) }

  # Add the lower nodes and link them to courses
  nodes = (requirements + programs).map { |big_node| big_node.map &add_requirement }

  # Link the upper nodes to the lower nodes
  big_nodes.zip(nodes).each &add_link

  # Add the auxiliary edges
  by_name = proc { |name, node| node.name == name }
  edges.each { |big_node, node| Edge.create(parent_id: Requirement.find(&by_name.curry.(big_node)).id, child_id: Requirement.find(&by_name.curry.(node)).id) }
end
