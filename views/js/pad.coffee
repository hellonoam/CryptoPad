@init = ->
  $("#passwordModal #password").keypress( (event) -> $("#passwordDone").click() if event.keyCode is 13 )
  $("#passwordModal").modal({keyboard: false})
  $("#passwordDone").click(->
    $.ajax
      url: "#{window.location.pathname}/authenticate"
      data:
        password: $("#password").val()
      success: (data) ->
        $("textarea").val(data)
  )