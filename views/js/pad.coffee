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
          # Kind of a hack to get the tooltip to change the text after it's set once.
          Common.TooltipText = data.responseText
          Common.showErrorTooltip($("#password"), (-> Common.TooltipText))
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
      complete: (data, xhr) ->
        if data.status is 200
          $(".deletePadSuccess").show()
          $("#deletePad").attr("disabled", true)
        else
          $(".deletePadFailed").show()

$(document).ready(=> Pad.init() )