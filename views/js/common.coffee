@init = ->
  $("#signupModal #signup").click(->
    $.ajax
      url: "/user"
      type: "POST"
      data:
        email: $("#signupModal input[type=email]").val()
      error: (data) ->
        console.log("ERROR: email save failed. data: #{data}")
  )

$(document).ready(=> @init() );