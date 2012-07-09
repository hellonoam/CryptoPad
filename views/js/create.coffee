class window.Create
  @FILESIZELIMIT = 20*1000*1000 # 20MB
  @FILECOUNTLIMIT = 4
  @fileList = []
  @securityOptions = {}

  @init = ->
    # Clearing the textarea and enabling fields in case the page is loaded from cache
    $("input, select, textarea").attr("disabled", false)
    $("textarea").val("")

    # Updating the securityOptions hash with the latest info from the form.
    $("form").change(=>
      @securityOptions = $("form").serializeObject()
      if @securityOptions.noPassword
        @securityOptions.encryptMethod = "serverSide"
      $("input[name=encryptMethod]").attr("disabled", @securityOptions.noPassword?)
      $("input[name=destroyAfterDays]," +
        "input[name=destroyAfterMultipleFailedAttempts]," +
        "select").attr("disabled", @securityOptions.neverDestroy?)
    )
    # Triggering change so the securityOptions will hold the default valued.
    $("form").change()

    $("#securityButton").click(-> $(".securityOptions").toggle("slow"))

    # launching the password dialog.
    $("#submitPad").click(=>
      if $("textarea").val() is "" and $("input[type=file]")[0].files.length is 0
        return Common.showErrorTooltip($("textarea"), "textarea is empty")
      if @securityOptions.noPassword
        return $("#passwordDone").click()
      $("#passwordModal").modal()
    )

    # mapping enter to clicking done.
    $("#passwordModal #password").keypress( (event) -> $("#passwordDone").click() if event.keyCode is 13 )

    # rendering the file names after files have been selected
    $("input[type=file]").change(=>
      @overSizeLimit = false
      @overCountLimit = false
      for file in $("input[type=file]")[0].files
        @overSizeLimit = true if file.size > @FILESIZELIMIT
        @overCountLimit = true if @fileList.length >= @FILECOUNTLIMIT
        @fileList.push file if file.size <= @FILESIZELIMIT and @fileList.length < @FILECOUNTLIMIT
      @renderFiles()
    )

    # sending the pad to the server.
    $("#passwordDone").click(=>
      text = $("textarea").val()
      text = " " if text is "" # gets rid of server error when encrypting an empty string
      nakedPass = $("#password").val()
      if !@securityOptions.noPassword? and (nakedPass is "" or nakedPass.length < 5)
        return Common.showErrorTooltip($("#password"), "choose a better password")
      pass = if @securityOptions.noPassword? then "" else Crypto.PBKDF2(nakedPass, true)
      formData = new FormData()
      if @securityOptions.encryptionMethod is "clientSide"
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
      # Appending security options.
      formData.append("securityOptions", JSON.stringify(@securityOptions))
      i = 0
      for file in @fileList
        formData.append("file#{i++}", file)
      # hiding the dialog
      $("#passwordModal").modal("hide")
      # Disabling all buttons
      $("input, select, textarea").attr("disabled", true)
      $(".status p").html("Your pad is uploading")
      $(".status .progress").removeClass("hide")
      $.ajax
        xhr: ->
          xhr = new XMLHttpRequest()
          xhr.upload.addEventListener("progress", (event) ->
            if (event.lengthComputable)
              percentComplete = Math.round((event.loaded / event.total) * 100)
              $(".status .progress .bar").width("#{percentComplete}%")
              $(".status h4").html("#{percentComplete}%")
          , false)
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
  # Also adds an X which removes the file from the list.
  @renderFiles = =>
    $(".overSizeLimitMessage").fadeIn("slow") if @overSizeLimit
    $(".overCountLimitMessage").fadeIn("slow") if @overCountLimit
    $(".fileslinks").html(Common.htmlForLinks(@fileList.map((file) -> file.name), "files:", false))
    $(".fileslinks .row").prepend("<a class='close' href='#'>x</a>")
    $(".fileslinks .row .close").click(->
      Create.overSizeLimit = false
      Create.overCountLimit = false
      filename = $(this).parent().find("a.filelink").attr("data-realName")
      Create.fileList = Create.fileList.filter((file) -> return file.name isnt filename)
      Create.renderFiles()
    )

$.fn.serializeObject = ->
    hash = {};
    for object in this.serializeArray()
      hash[object.name] = if object.value is "on" then true else object.value
    hash

$(document).ready(=> Create.init() )