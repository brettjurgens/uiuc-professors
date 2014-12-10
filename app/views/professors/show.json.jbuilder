json.extract! @professor, :f_name, :l_name, :address, :netid, :phone, :role, :first_initial, :department, :image_url
json.sections do
  json.partial! 'sections/section.json', collection: @professor.sections, as: :section
end