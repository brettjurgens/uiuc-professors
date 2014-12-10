require_relative 'uiuc_course_parser'
require_relative 'uiuc_professor_parser'

namespace :uiuc_parser do
  desc "parse courses"
  task courses: :environment do
    puts "running parse task"
    UIUCCourseParse.parse_semester
  end

  desc "parse professors"
  task professors: :environment do
    puts "running professors parse"
    UIUCFacultyParse.parse_faculty
  end

end