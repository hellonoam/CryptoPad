class window.Common
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
          setTimeout((=> $("#signupModal").modal("hide")), 2000)
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

  @htmlForLinks = (filenames) ->
    return "" if filenames?.length == 0
    "<p class='span4'>You've got some files as well:</p><div class='span4'>"
    for filename in filenames
      links += "<div class='row'>" +
                  "<a class='span1' href='#{window.location.pathname}/files/#{filename}'>" +
                    "#{filename}" +
                  "</a>" +
                "</div>"
    links += "</div>"
    links

$(document).ready(=> Common.init() )