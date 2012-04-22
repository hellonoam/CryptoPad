class window.Create
  @client_side_encryption = false

  @init = ->
    $("#securityButton").tooltip({ title: "private beta" })

    # launching the password dialog.
    $("#submitPad").click(=>
      if $("textarea").val() is "" and $("input[type=file]")[0].files.length is 0
        return Common.showErrorTooltip($("textarea"), "textarea is empty")
      $("#passwordModal").modal()
    )

    # mapping enter to clicking done.
    $("#passwordModal #password").keypress( (event) -> $("#passwordDone").click() if event.keyCode is 13 )

    # rendering the file names after files have been selected
    $("input[type=file]").change(->
      filenames = []
      for file in this.files
        filenames.push file.name
      $(".fileslinks").html(Common.htmlForLinks(filenames, "files:", false))
    )

    # sending the pad to the server.
    $("#passwordDone").click(=>
      text = $("textarea").val()
      text = " " if text is "" # gets rid of server error when encrypting an empty string
      nakedPass = $("#password").val()
      return Common.showErrorTooltip($("#password"), "choose a better password") if nakedPass is ""
      pass = Crypto.PBKDF2(nakedPass, true)
      formData = new FormData()
      if @client_side_encryption
        # TODO: make this random.
        salt = "salty"
        cryptedHash = JSON.parse(Crypto.encrypt(text, nakedPass, salt))
        formData.append("password", pass)
        formData.append("salt", salt)
        formData.append("iv", cryptedHash.iv)
        formData.append("encrypted_text", cryptedHash.ct)
        formData.append("encrypt_method", "client_side")
      else
        formData.append("password", pass)
        formData.append("text", text)
      fileList = $("input[type=file]")[0].files
      formData.append("filesCount", fileList.length)
      i = 0
      for file in fileList
        formData.append("file#{i++}", file)
      $.ajax
        url: "/pads"
        type: "POST"
        data: formData
        processData: false  # tell jQuery not to process the data used because of file upload.
        contentType: false  # tell jQuery not to set contentType used because of file upload.
        success: (data) ->
          $("#passwordModal").modal("hide")
          $.ajax
            url: "/link/#{data.hash_id}"
            success: (linkHtml) ->
              $(".main").html(linkHtml)
        error: (data) ->
          console.log("ERROR: #{data}")
    )
  
  @uploadFile = (file) ->
    return unless file?
    formData = new FormData()
    formData.append("file", file)
    $.ajax({
      url: "/upload"
      type: "POST"
      data: formData
      processData: false  # tell jQuery not to process the data
      contentType: false   # tell jQuery not to set contentType
    });

$(document).ready(=> Create.init() )