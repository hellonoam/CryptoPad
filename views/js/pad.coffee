@init = ->
  $("#passwordModal").modal({keyboard: false})
  $("#passwordDone").click(->
    $.ajax
      url: "#{window.location.pathname}/authenticate"
      data:
        password: $("#password").val()
      success: (data) ->
        $("textarea").val(data)
  )