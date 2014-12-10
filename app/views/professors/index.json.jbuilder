json.array!(@professors) do |professor|
  json.extract! professor, :id, :f_name, :l_name, :first_initial
  json.url professor_url(professor, format: :json)
end