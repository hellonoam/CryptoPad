@init = ->
  $("#password").focus(-> $("#password").removeClass("error"))
  $("#passwordModal #password").keypress( (event) -> $("#passwordDone").click() if event.keyCode is 13 )
  $("#passwordModal").modal({keyboard: false})
  $("#passwordDone").click(->
    $.ajax
      url: "#{window.location.pathname}/authenticate"
      data:
        password: $("#password").val()
      success: (data) ->
        $("#passwordModal").modal("hide")
        $("textarea").val(data)
      error: (data) ->
        $("#password").addClass("error")
        $("#password").tooltip( title: "incorrect password", trigger: "manual" )
        $("#password").tooltip("show")
        setTimeout((-> $("#password").tooltip("hide")), 2000)
  )

$(document).ready(=> @init() );