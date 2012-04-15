class window.Create

  constructor: ->
    # removing error class on focus
    $("textarea").focus(-> $("textarea").removeClass("error"))
    $("#password").focus(-> $("#password").removeClass("error"))

    # launching the password dialog.
    $("#submitPad").click(->
      # TODO: add a tooltip maybe.
      return $("textarea").addClass("error") if $("textarea").val() is ""
      $("#passwordModal").modal()
    )

    # mapping enter to clicking done.
    $("#passwordModal #password").keypress( (event) -> $("#passwordDone").click() if event.keyCode is 13 )

    # sending the pad to the server.
    $("#passwordDone").click(->
      text = $("textarea").val()
      pass = $("#password").val()
      return $("#password").addClass("error")  if pass is ""
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
