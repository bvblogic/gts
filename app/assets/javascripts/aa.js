#= require jquery
#= require jquery-ui
#= require active_admin/base
#= require active_admin/select2

$(function() {
  var append_place, element, href, obj;
  element = $("#current_user_logo");
  obj = element.find("a");
  href = obj.attr('href');
  href = "http://www.audiotool.com/images/no-avatar-128.gif";
  append_place = $("#current_user");
  append_place.after("<img src=" + href + " height='40'>");
  element.remove();
  if ($(".col-progress").length) {
    $.each($(".col-progress"), function(index, value) {
      var number_value;
      number_value = parseInt($(value).html());
      if (index > 0) {
        if ($(value).parent().find(".col-status").html() !== '') {
          $(value).html('');
          if (number_value > 0) {
            $(value).append("<div class='board'></div>");
            return $(value).find('.board').progressbar({
              value: number_value
            });
          } else {
            return $(value).append("<div class='board'></div>");
          }
        }
      }
    });
  }
  $(".has_many_container.sub_goals").on('click', ".button.show", function() {
    var goal;
    if ($(this).parents(".inputs.has_many_fields").find(".dispnone").length) {
      goal = $(this).parents(".inputs.has_many_fields").find(".dispnone");
    } else {
      goal = $(this).parents(".inputs.has_many_fields").find(".disp");
    }
    if ($(this).html() === "Show step") {
      goal.show();
      return $(this).html("Hide step");
    } else if ($(this).html() === "Hide step") {
      goal.hide();
      return $(this).html("Show step");
    }
  });
  return $(".has_many_container.sub_goals").on('keyup', ".name_field", function() {
    var text;
    text = $(this).parents(".inputs.has_many_fields").find(".step_name");
    return $(text).html("Step " + $(this).val());
  });
});
