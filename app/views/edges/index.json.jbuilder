json.array!(@edges) do |edge|
  json.extract! edge, :id
  json.url edge_url(edge, format: :json)
end
