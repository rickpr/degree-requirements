require 'rails'
require 'pry'


# The root folder above all the college
BigFolder = 'files'
# File containing dups
DupsFile  = 'dups.json'
# Folder to drop the output in (within BigFolder)
OutputFolder = 'output'

# Enter the big folder
Dir.chdir BigFolder

# Get files from JSON
from_json = proc { |file| JSON.parse File.read file }

# Get all files except the dup file
files = Dir.glob('*').reject { |file| file == DupsFile }
# Get the dup file
dups = from_json.call DupsFile

# This makes the university structure
structure = files.map do |folder|
  { folder.titleize =>
    Dir.glob(File.join(folder,'*')).map{ |file| { File.basename(file, ".json").titleize => from_json.call(file) } }.reduce(:merge)
  }
end.reduce(:merge)

# This gets the size of each college
college_sizes = structure.map{ |college, programs| { college => programs.size } }.reduce :merge

# This procedure assists in finding duplicates by finding hashes with no values
empty_values = proc { |hsh| hsh.values.flatten.empty? }

# This is a map of all the duplicates by which colleges and programs include them
dupmap = dups.map do |requirement|
  { requirement => 
    structure.map do |college, programs| 
      { college =>
        programs.map{ |key, values| { key => values } if values.map { |val| val["name"] }.include?(requirement["name"]) }.compact
      }
    end.reject(&empty_values).reduce(:merge)
  }
end.reject(&empty_values).reduce(:merge)

# This lists duplicates by college only
dups_by_college = dupmap.merge(dupmap) { |key, value| value.map{ |inner_key, inner_value| { inner_key => inner_value.size } }.reduce(:merge) }

# If a requirement is in more than half of a college's degrees, it is a college requirement.
college_requirements = dups_by_college.merge(dups_by_college) do |_, value|
  value.select { |inner_key, inner_value| inner_value.to_i >= college_sizes[inner_key] / 2.0 }
end.reject { |_, value| value.empty? }

# If a requirement is a college requirement in more than three of the colleges,
# it is a university requirement.

university = college_requirements.select { |key, value| value.size.to_f >= 3 } 

# The college requirements map is currently in reverse. This must be fixed.
requirement_by_college = college_requirements.map do |requirement, colleges|
  colleges.keys.map do |college|
    { college => [requirement] }
  end
end.flatten.reduce { |hash, incoming| hash.merge(incoming) { |college, requirement_array, requirement| requirement_array + requirement } }

# Now, let's get the structure without the college requirements in there.
final_structure = structure.merge(structure) do |college, programs|
  programs.merge(programs) { |_, requirements| requirements.reject { |req| requirement_by_college[college].include?(req) } }
end

programs_by_college = structure.merge(structure) { |_,program| program.keys }

# Now, the university requirements must be removed from the college requirements.
requirement_by_college.merge!(requirement_by_college) { |_,requirements| requirements.reject { |req| university.include?(req) } }

# Time to write the final files
write_json = proc { |var, file| file.write JSON.pretty_generate(var) }
FileUtils::mkdir_p OutputFolder
Dir.chdir OutputFolder

# Write each degree program
final_structure.each do |college, programs|
  folder = college.underscore
  FileUtils::mkdir_p folder
  programs.each do |degree, requirements|
    filename = File.join(folder, degree.underscore)
    File.open(filename + ".json", "w", &write_json.curry.(requirements))
  end
end

# Write each set of college requirements
FileUtils::mkdir_p "colleges"
requirement_by_college.each do |college, requirements|
  filename = File.join("colleges", college.underscore)
  File.open(filename + ".json", "w", &write_json.curry.(requirements))
end

# Write the set of university requirements
File.open("university_core.json", "w", &write_json.curry.(university))

# Create the edges. Note this is another inside-out hash.
college_edges = final_structure.map do |college, majors|
  majors.keys.map { |major| { major => college } }
end.flatten

university_edges = final_structure.keys.map { |college| { college => "University Core" } }

edges = college_edges + university_edges

File.open("edges.json", "w", &write_json.curry.(edges))

binding.pry
