class Common
  @init = ->
    $("#signupModal input[type=email]").keypress( (event) ->
      $("#signupModal #signup").click() if event.keyCode is 13
    )
    $("#signupModal #signup").click(=>
      email = $("#signupModal input[type=email]").val()
      if email is ""
        return @showErrorTooltip($("#signupModal input[type=email]"), "invalid email")
      $.ajax
        url: "/user"
        type: "POST"
        data:
          email: email
        success: ->
          setTimeout((=> $("#signupModal").modal("hide")), 1500)
          $(".modal-body").html("Thanks!")
          $("#signupModal #signup").attr("disabled", "true")
        error: (data) ->
          console.log("ERROR: email save failed. data: #{data}")
    )

  @showErrorTooltip = (element, text) ->
    element.focus(-> element.removeClass("error"))
    element.addClass("error")
    element.tooltip( title: text, trigger: "manual" )
    element.tooltip("show")
    setTimeout((-> element.tooltip("hide")), 2000)

$(document).ready(=> Common.init() )