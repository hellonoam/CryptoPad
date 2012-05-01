class window.Common
  @init = ->
    # Clicking on the close link removes the alert
    $(".alert .close").click(-> $(this).parent().fadeOut("slow"))

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
          setTimeout((-> $("#signupModal").modal("hide")), 2000)
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

  # TODO: avoid XSS
  @htmlForLinks = (filenames, title, withLinks) ->
    return "" if filenames?.length == 0
    html = "<p class='span4'>#{title}</p><div class='span4'>"
    for filename in filenames
      link = if withLinks then "#{window.location.pathname}/files/#{filename}" else "#"
      target = if withLinks then "target='_blank'" else ""
      html += "<div class='row'>" +
                  "<a class='filelink' data-realName='#{filename}' href='#{link}' #{target}>" +
                    "#{if filename.length > 40 then filename.substr(0,37) + '...' else filename}" +
                  "</a>" +
                "</div>"
    html += "</div>"
    html

$(document).ready(=> Common.init() )