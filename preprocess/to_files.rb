require 'rails'
require 'pry'

RequirementsFile = "pretty_reqs.json"
OutputFolder     = "files"

all_reqs = JSON.parse(File.read(RequirementsFile))

# Some requirements have degree_term_items, some have terms
degree_terms = all_reqs.select { |degree| degree["degree_term_items"] }
terms        = all_reqs.select { |degree| degree["terms"] }


# The prerequisites array is always invalid and empty
#
# This checks if courses are already included, and sums the credits if they are
sum_courses = proc do |array, hash|
  # Checks to see if it's already in the array
  included = array.find { |hsh| hsh["name"] == hash["name"] }
  # Add the credits keys, keep the rest the same
  included.merge(hash) { |key, old, new| key == "credits" ? old + new : old } if included
  # If nothing was found, use the first hash
  included ||= hash
  array << included
end

# Fix the hash format of the degree_terms array
fix_hash = proc { |item_hash| { "name" => item_hash["name"], "courses" => [] } }

# Map name to term items for the terms array
format_hash = proc do |item_hash|
  { "name"      => item_hash["name"],
    "min_grade" => item_hash["min_grade"],
    "credits"   => item_hash["credits"],
    "courses"   => item_hash["courses"].map { |hsh| hsh["number"] }
  }
end
################################
# Begin assembling the arrays #
###############################
degree_terms.map! do |degree|
  { "name"         => degree["name"],
    "requirements" => degree["degree_term_items"].map(&fix_hash).reduce([], &sum_courses)
  } 
end

terms.map! do |degree|
  { "name"         => degree["name"],
    "college"      => degree["college"],
    "requirements" => degree["terms"].flat_map{ |terms| terms["term_items"].map(&format_hash) }.reduce([], &sum_courses)
  }
end


output = degree_terms + terms


# Write the JSON files

write_json = proc { |var, file| file.write JSON.pretty_generate(var) }
FileUtils::mkdir_p OutputFolder
Dir.chdir OutputFolder

output.each do |degree|
  folder_name = degree["college"] || "unknown"
  folder      = folder_name.underscore
  FileUtils::mkdir_p folder
  filename = File.join(folder, degree["name"].underscore)
  File.open(filename + ".json", "w", &write_json.curry.(degree["requirements"]))
end


# Find duplicates to search for common requirements

reqs_only = output.map { |degree| degree["requirements"] }
# This iterates through the array and finds requirements that are shared by programs.
dups = reqs_only.map.with_index{ |requirement, index| [requirement].product(reqs_only[0...index]).map { |pair| pair.reduce(:&) } }
target = dups.flatten.uniq
File.open("dups.json","w", &write_json.curry.(target))
