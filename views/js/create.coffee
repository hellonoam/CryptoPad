@init = ->
  # removing error class on focus
  $("textarea").focus(-> $("textarea").removeClass("error"))
  $("#password").focus(-> $("#password").removeClass("error"))

  # launching the password dialog.
  $("#submitPad").click(->
    if $("textarea").val() is ""
      $("textarea").tooltip( title: "textarea is empty", trigger: "manual" )
      $("textarea").tooltip("show")
      setTimeout((-> $("textarea").tooltip("hide")), 2000)
      return $("textarea").addClass("error")
    $("#passwordModal").modal()
  )

  # mapping enter to clicking done.
  $("#passwordModal #password").keypress( (event) -> $("#passwordDone").click() if event.keyCode is 13 )

  # sending the pad to the server.
  $("#passwordDone").click(->
    text = $("textarea").val()
    pass = $("#password").val()
    if pass is ""
      $("#password").tooltip( title: "choose a better password", trigger: "manual" )
      $("#password").tooltip("show")
      setTimeout((-> $("#password").tooltip("hide")), 2000)
      return $("#password").addClass("error")
    $("#passwordModal").modal("hide")
    $.ajax
      url: "/pads"
      type: "POST"
      data:
        text: text
        password: pass
      success: (data) ->
        $.ajax
          url: "/link/#{data.hash_id}"
          success: (linkHtml) ->
            $(".main").html(linkHtml)
      error: (data) ->
        console.log("ERROR: #{data}")
  )


$(document).ready(=> @init() );