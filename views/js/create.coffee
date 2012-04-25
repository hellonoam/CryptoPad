class window.Create
  @client_side_encryption = false
  @FILESIZELIMIT = 20*1000*1000 # 20MB
  @FILECOUNTLIMIT = 4
  @fileList = []

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
    $("input[type=file]").change(=>
      @overSizeLimit = false
      @overCountLimit = false
      for file in $("input[type=file]")[0].files
        if file.size > @FILESIZELIMIT
          @overSizeLimit = true
        if @fileList.length >= @FILECOUNTLIMIT
          @overCountLimit = true
        if file.size <= @FILESIZELIMIT and @fileList.length < @FILECOUNTLIMIT
          @fileList.push file
      @renderFiles()
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
        # TODO: make this more random.
        salt = "#{Math.round(Math.random()*10000)}"
        cryptedHash = JSON.parse(Crypto.encrypt(text, nakedPass, salt))
        formData.append("password", pass)
        formData.append("salt", salt)
        formData.append("iv", cryptedHash.iv)
        formData.append("encrypted_text", cryptedHash.ct)
        formData.append("encrypt_method", "client_side")
      else
        formData.append("password", pass)
        formData.append("text", text)
      formData.append("filesCount", @fileList.length)
      i = 0
      for file in @fileList
        formData.append("file#{i++}", file)
      # hiding the dialog
      $("#passwordModal").modal("hide")
      $.ajax
        xhr: ->
          $(".status p").html("Your pad is uploading")
          $(".status .progress").removeClass("hide")
          xhr = new XMLHttpRequest()
          xhr.upload.addEventListener("progress", (event) ->
            if (event.lengthComputable)
              percentComplete = Math.round((event.loaded / event.total) * 100)
              $(".status .progress .bar").width("#{percentComplete}%")
              $(".status h4").html("#{percentComplete}%")
              console.log "#{percentComplete}%"
          )
          return xhr
        url: "/pads"
        type: "POST"
        data: formData
        processData: false  # tell jQuery not to process the data used because of file upload.
        contentType: false  # tell jQuery not to set contentType used because of file upload.
        success: (data) ->
          $.ajax
            url: "/link/#{data.hash_id}"
            success: (linkHtml) ->
              $(".main").html(linkHtml)
        error: (data) ->
          console.log("ERROR: #{data}")
    )

  # Renders the filelist with appropriate warning messages if needed on the page.
  @renderFiles = =>
    if @overSizeLimit
      $(".overSizeLimitMessage").fadeIn("slow")
      $(".overSizeLimitMessage .close").click(-> $(".overSizeLimitMessage").fadeOut("slow"))
    if @overCountLimit
      $(".overCountLimitMessage").fadeIn("slow")
      $(".overCountLimitMessage .close").click(-> $(".overCountLimitMessage").fadeOut("slow"))
    $(".fileslinks").html(Common.htmlForLinks(@fileList.map((file) -> file.name), "files:", false))

$(document).ready(=> Create.init() )