json.array!(@requirements) do |requirement|
  json.extract! requirement, :id, :name, :min_grade, :hours, :take, :type
  json.url requirement_url(requirement, format: :json)
end
