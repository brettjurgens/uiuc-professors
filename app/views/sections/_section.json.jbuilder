json.extract! section, :crn, :term, :section_name, :course_id
json.course do
  json.partial! 'courses/course.json', course: section.course
end