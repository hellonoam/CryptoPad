class Create
  @client_side = true

  @init = ->
    $("#securityButton, #filesButton").tooltip({ title: "private beta" })

    # launching the password dialog.
    $("#submitPad").click(->
      return Common.showErrorTooltip($("textarea"), "textarea is empty") if $("textarea").val() is ""
      $("#passwordModal").modal()
    )

    # mapping enter to clicking done.
    $("#passwordModal #password").keypress( (event) -> $("#passwordDone").click() if event.keyCode is 13 )

    # sending the pad to the server.
    $("#passwordDone").click(=>
      text = $("textarea").val()
      nakedPass = $("#password").val()
      pass = Crypto.PBKDF2(nakedPass, true)
      if @client_side
        # TODO: make this random.
        salt = "salty"
        cryptedHash = JSON.parse(Crypto.encrypt(text, nakedPass, salt))
        data =
          password: pass
          salt: salt
          iv: cryptedHash.iv
          encrypted_text: cryptedHash.ct
          encrypt_method: "client_side"
      else
        data = { text: text, password: pass }
      return Common.showErrorTooltip($("#password"), "choose a better password") if pass is ""
      $("#passwordModal").modal("hide")
      $.ajax
        url: "/pads"
        type: "POST"
        data: data
        success: (data) ->
          $.ajax
            url: "/link/#{data.hash_id}"
            success: (linkHtml) ->
              $(".main").html(linkHtml)
        error: (data) ->
          console.log("ERROR: #{data}")
    )

$(document).ready(=> Create.init() )