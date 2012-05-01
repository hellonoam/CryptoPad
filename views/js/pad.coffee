class Pad
  @init = ->
    $("textarea").val("")

    # Mapping enter to click in dialog.
    $("#passwordModal #password").keypress( (event) -> $("#passwordDone").click() if event.keyCode is 13 )

    @hashId = $(".hashId").attr("data-hashId")
    @noPassword = $("#passwordModal").attr("data-noPassword") == "true"

    $("#deletePad").click(@delete)

    # Sending the password.
    $("#passwordDone").click(=>
      nakedPass = $("#password").val()
      pass = if @noPassword then "" else Crypto.PBKDF2(nakedPass, true)
      $.ajax
        url: "#{window.location.pathname}/authenticate"
        data:
          password: pass
        success: (data) ->
          if data.encrypt_method == "server_side"
            $("textarea").val(data.text)
            $(".deletePad").show() if data.allow_reader_to_destroy
          else
            $("textarea").val(Crypto.decrypt(data.encrypted_text, nakedPass, data.salt, data.iv))
          $(".fileslinks").html(Common.htmlForLinks(data.filenames, "You've got some files as well:", true))
          $("#passwordModal").modal("hide")
        error: (data) ->
          Common.showErrorTooltip($("#password"), "incorrect password")
    )

    # The password dialog is launched only if the pad needs a password
    if @noPassword
      $("#passwordDone").click()
    else
      $("#passwordModal").modal({keyboard: false})

  @delete = =>
    $.ajax
      type:"delete"
      url:"/pads/#{@hashId}"
      complete:
        console.log "add feedback"

$(document).ready(=> Pad.init() )