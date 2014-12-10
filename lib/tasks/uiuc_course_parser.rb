require 'typhoeus'
require 'nokogiri'

class UIUCCourseParse
  @base_url = 'http://courses.illinois.edu/cisapp/explorer/schedule/'
  @hydra = Typhoeus::Hydra.new(max_concurrency: 200)

  # move out
  @year = '2015'
  @semester = 'spring'

  @term = "#{@year}/#{@semester}"

  def self.parse_semester
    url = "#{@base_url}#{@year}/#{@semester}.xml"
    @hydra.queue(request = Typhoeus::Request.new(url))
    puts "Parse: #{url}"

    request.on_complete do |response|
      doc = Nokogiri::XML(response.response_body)
      doc.css('subject').each do |subject|
        parse_subject(subject.attr('href'))
      end
      parse_subject(doc.css('subject').first.attr('href'))
    end

    @hydra.run
  end

  def self.parse_subject(url)
    @hydra.queue(request = Typhoeus::Request.new(url))
    puts "Parse: #{url}"

    request.on_complete do |response|
      doc = Nokogiri::XML(response.response_body)
      doc.css('course').each do |course|
        parse_course(course.attr('href'))
      end
    end

    @hydra.run
  end

  def self.parse_course(url)
    @hydra.queue(request = Typhoeus::Request.new(url))
    puts "Parse: #{url}"

    request.on_complete do |response|
      doc = Nokogiri::XML(response.response_body)

      # get the course info
      course_info = doc.xpath('//ns2:course').attr('id').value.split(" ")
      course_name = doc.css('label').children.first.text

      # find or create the course
      course = Course.where(:department => course_info[0], :course_num => course_info[1].to_i).first_or_create(:name => course_name)

      doc.css('section').each do |section|
        parse_section(section.attr('href'), course)
      end
    end

    @hydra.run
  end

  def self.parse_section(url, course)
    @hydra.queue(request = Typhoeus::Request.new(url))
    puts "Parse: #{url}"

    request.on_complete do |response|
      doc = Nokogiri::XML(response.response_body)
      doc.css('meeting').each do |section|
        # get the CRN
        crn = doc.xpath('//ns2:section').attr('id').value
        
        # get the section name & strip whitespace
        section_name = doc.css('sectionNumber').children.text.strip

        # make the section
        new_section = Section.where(:crn => crn).first_or_create(:term => @term, :section_name => section_name)

        # add the section to the course
        course.sections << new_section
        course.save

        # get the professor(s)
        section.css('instructor').each do |instructor|
          professor = Professor.where(:first_initial => instructor.attr('firstName'), :l_name => instructor.attr('lastName')).first_or_create
          professor.sections << new_section
          professor.save
        end
      end
    end

    @hydra.run
  end
end