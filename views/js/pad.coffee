class Pad
  @init = ->
    $("textarea").val("")

    $("#passwordModal #password").keypress( (event) -> $("#passwordDone").click() if event.keyCode is 13 )

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

    # The password dialog is launched only if the pad needs a password
    if $("#passwordModal").attr("data-noPassword") == "true"
      $("#passwordDone").click()
    else
      $("#passwordModal").modal({keyboard: false})

$(document).ready(=> Pad.init() )