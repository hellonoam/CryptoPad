class Create
  @init = ->
    # launching the password dialog.
    $("#submitPad").click(->
      return Common.showErrorTooltip($("textarea"), "textarea is empty") if $("textarea").val() is ""
      $("#passwordModal").modal()
    )

    # mapping enter to clicking done.
    $("#passwordModal #password").keypress( (event) -> $("#passwordDone").click() if event.keyCode is 13 )

    # sending the pad to the server.
    $("#passwordDone").click(->
      text = $("textarea").val()
      pass = $("#password").val()
      return Common.showErrorTooltip($("#password"), "choose a better password") if pass is ""
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


$(document).ready(=> Create.init() )