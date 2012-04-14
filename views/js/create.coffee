class window.Create

  constructor: ->
    $("#passwordDone").click(->
      text = $("textarea").val()
      pass = $("#password").val()
      # TODO: show error message
      return console.log("ERROR: emptry text or pass") if text is "" or pass is ""
      $.ajax
        url: "/pads"
        type: "POST"
        data:
          text: text
          password: pass
        success: (data) ->
          console.log(data.hash_id)
          $.ajax
            url: "/link/#{data.hash_id}"
            success: (linkHtml) ->
              $(".main").html(linkHtml)
        error: (data) ->
          console.log("ERROR: #{data}")
    )
