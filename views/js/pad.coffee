class Pad
  @init = ->
    $("#passwordModal #password").keypress( (event) -> $("#passwordDone").click() if event.keyCode is 13 )
    $("#passwordModal").modal({keyboard: false})
    $("#passwordDone").click(->
      nakedPass = $("#password").val()
      $.ajax
        url: "#{window.location.pathname}/authenticate"
        data:
          password: Crypto.PBKDF2(nakedPass, true)
        success: (data) ->
          $("#passwordModal").modal("hide")
          if data.encrypt_method == "server_side"
            $("textarea").val(data.text)
          else
            $("textarea").val(Crypto.decrypt(data.encrypted_text, nakedPass, data.salt, data.iv))
        error: (data) ->
          Common.showErrorTooltip($("#password"), "incorrect password")
    )

$(document).ready(=> Pad.init() )