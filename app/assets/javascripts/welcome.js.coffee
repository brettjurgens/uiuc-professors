# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
$ -> 
  professors = new Bloodhound(
    datumTokenizer: Bloodhound.tokenizers.obj.whitespace('name'),
    queryTokenizer: Bloodhound.tokenizers.whitespace,
    limit: 10,
    prefetch:
      url: 'professors.json',
      filter: (list) ->
        $.map list, (professor) ->
          if professor.f_name != null
            name: professor.f_name + " " + professor.l_name
            id: professor.id
          else
            name: professor.first_initial + " " + professor.l_name
            id: professor.id
  )

  professors.initialize()

  $("#prefetch .typeahead").typeahead null,
    name: "professors"
    displayKey: "name"
    
    # `ttAdapter` wraps the suggestion engine in an adapter that
    # is compatible with the typeahead jQuery plugin
    source: professors.ttAdapter()

  parseProfessorData = (data) ->
    result_container = $('#results')

    if typeof(data.f_name) == "undefined" || data.f_name == null
      data.f_name = data.first_initial

    courses = []
    course_index_mapper = {}
    map_i = 0

    # group by courses instead of sections
    $.each data.sections, (i, val) ->
      course_id = course_index_mapper[val.course_id]
      if typeof(course_id) == "undefined" || course_id == null
        course_index_mapper[val.course_id] = map_i
        course_id = map_i++
        courses[course_id] = {}
        courses[course_id].number = val.course.department + val.course.course_num
        courses[course_id].name = val.course.name
        courses[course_id].sections = []

      # no need for more data...
      delete val.course

      courses[course_id].sections.push val

    delete data.sections
    
    data.courses = courses

    # update address. We should only need everything before the first comma 
    # (this should be the office)
    address = /^(.+?),/.exec(data.address)
    if address != null && address[1] != null
      data.address = address[1]

    template = $('#template').html()
    Mustache.parse template
    rendered = Mustache.render template, data
    console.log(data)
    result_container.empty().html(rendered)


  $('.typeahead').on 'typeahead:selected', (obj, datum, name) ->
    $.get '/professors/' + datum.id + '.json', parseProfessorData