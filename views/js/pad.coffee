class Pad
  @init = ->
    $("textarea").val("")
    $("#passwordModal #password").keypress( (event) -> $("#passwordDone").click() if event.keyCode is 13 )
    $("#passwordModal").modal({keyboard: false})
    $("#passwordDone").click(->
      nakedPass = $("#password").val()
      $.ajax
        url: "#{window.location.pathname}/authenticate"
        data:
          password: Crypto.PBKDF2(nakedPass, true)
        success: (data) ->
          if data.encrypt_method == "server_side"
            $("textarea").val(data.text)
          else
            $("textarea").val(Crypto.decrypt(data.encrypted_text, nakedPass, data.salt, data.iv))
          $(".fileslinks").html(Common.htmlForLinks(data.filenames, "You've got some files as well:", true))
          $("#passwordModal").modal("hide")
        error: (data) ->
          Common.showErrorTooltip($("#password"), "incorrect password")
    )

$(document).ready(=> Pad.init() )