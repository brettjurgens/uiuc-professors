require 'typhoeus'
require 'nokogiri'
require 'vcardigan'
require 'open-uri'
require 'google-search'

class UIUCFacultyParse
  @directory_url = 'http://illinois.edu/ds/facultyListing'
  @search_base = 'http://illinois.edu/ds/search?search_type=staff&search=' # + f_initial*+last
  @vcard_base = 'https://illinois.edu/ds/vCard/person/' # + netid
  @hydra = Typhoeus::Hydra.new(max_concurrency: 200)

  def self.parse_faculty
    @hydra.queue(request = Typhoeus::Request.new(@directory_url))
    puts "Parse: #{@directory_url}"

    request.on_complete do |response|
      doc = Nokogiri::HTML(response.response_body)

      # find all staff in directory:
      staff = doc.css('.ws-ds-category-desc li a')

      staff.each do |employee|
        # get their name
        last, first = employee.children.to_s.gsub(',', '').split(' ')

        puts "looking for: #{first} #{last}"

        professor = Professor.where(:first_initial => first[0], :l_name => last).first

        if !professor.nil? and professor.f_name.nil?    # no need to do this everytime...
          # update first name
          professor.f_name = first if professor.f_name.nil?

          # get netid
          match = employee.attributes['href'].value.match(/search=(.*)@illinois/)
          netid = match[1] if !match[1].nil?

          if !netid.nil?
            get_vcard(netid, professor)
          end

          professor.save
        end

      end

      fill_in_missing_professors()

      get_missing_images()

    end

    @hydra.run
  end

  def self.fill_in_missing_professors
    professors = Professor.where(:f_name => nil, :name_too_vague => false)

    professors.each do |professor|
      # build URL
      search_for_professor(professor)
    end
  end

  # set the image to the first google images result with netid and site:illinois.edu
  def self.get_missing_images
    professors = Professor.where('image_url IS NULL AND netid IS NOT NULL')

    professors.each do |professor|
      get_image_for_professor(professor)
    end
  end

  def self.get_image_for_professor(professor)
    puts "looking for #{professor.netid}"
    img = Google::Search::Image.new(:query => "site:illinois.edu #{professor.netid}").first
    if !img.nil?
      professor.image_url = img.uri
      professor.save
    end
  end

  def self.search_for_professor(professor)
    url = "#{@search_base}#{professor.first_initial}*+#{professor.l_name}"
    puts "Checking out #{url}"
    @hydra.queue(request = Typhoeus::Request.new(url))

    request.on_complete do |response|
      doc = Nokogiri::HTML(response.response_body)

      if doc.css('.ws-ds-detail').length > 0
        # get netid
        netid_matches = doc.css('.ws-ds-email').to_s.match(/Illinois\('(.*)'\)/)
        netid = netid_matches[1] if !netid_matches.nil?
        get_vcard(netid, professor)
      else 
        results = doc.css('#ws-ds-person tbody tr')

        if !results.nil? && results.length > 0
          # the illinois directory sucks.
          # seriously.
          i = 0
          if results.length <= 3
            netid_matches = results[2].css('.ws-ds-search-email').to_s
                                   .match(/Illinois\('(.*)'\)/)
            netid = netid_matches[1] if !netid_matches.nil?
            get_vcard(netid, professor)
          else
            while i < results.length
              role = results[i + 2].css('.ws-ds-search-role').to_s
              if role.downcase.include?('lecturer') or role.downcase.include?('prof')
                netid_matches = results[i + 2].css('.ws-ds-search-email').to_s
                                                .match(/Illinois\('(.*)'\)/)
                get_vcard(netid_matches[1], professor) if !netid_matches.nil?
                break
              end
              i += 3
            end # while loop
          end # if/else
        elsif doc.to_s.downcase.include?('blocked')
          # break if we're blocked from searching :(
          puts "We've been blocked from searching..."
          break
        else # the name is too vague. i.e. J. Smith
          professor.name_too_vague = true
          professor.save
        end # if !results.nil?
      end # if/else ws-ds-length
    end # request on_complete
    @hydra.run
  end

  def self.get_vcard(netid, professor)
    puts "grabbing #{netid}'s vcard"
    url = @vcard_base + netid
    professor.netid = netid

    vcard = VCardigan.parse(open(url))
    
    if !vcard.nil?
      professor.department = vcard.org.first.values.first if !vcard.org.nil?
      professor.phone = vcard.tel.first.values.first if !vcard.tel.nil?
      professor.role = vcard.title.first.values.first if !vcard.title.nil?
      professor.l_name, professor.f_name = vcard.n.first.values if !vcard.n.nil?
      professor.image_url = vcard.photo.first.values.first if !vcard.photo.nil?
      professor.address = vcard.adr.first.values.reject(&:empty?).join("\n") if !vcard.adr.nil?
    end

    professor.save
  end

end