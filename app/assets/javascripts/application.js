//= require jquery
//= require jquery-ui
//= require jquery_ujs
//= require jquery.remotipart
//= require jquery-1.11.1.min
//= require build.min

$(document).ready(function(){
  detectOutdatedBrowser();
  openFilters();
  hideFilters();
  hoverIcon();
  removeInfoMsg();
  
  $(".batch_action").click(function(){
    ids = [];
    $('.check').each(function(){
      if ($(this).is(":checked")) {
      ids.push($(this).attr('id'))
      }
    });
  $("#batch_action_name").val($(this).attr('data-action'));
  $("#batch_ids").val(ids);
  $("#BatchForm").submit();
  })

  $("#collapse_substep").click(function(event){
    event.preventDefault();
    $("#step<%=@parent_id%>").slideUp(500);
  });

  // Initialization
  $(".chosen-select").chosen({
    disable_search: true,
    width: '100%'
  });
 
  if ($('.calendar, .calendar_in_filters').length) {
    $('.calendar').datepicker({
    });
    $('.calendar_in_filters').datepicker({
    });
  }

  $("input:file").on('change', function() {
    if ($(this).val() == "") {
        return;
    }
    var fileInputContent = $(this).val().split("\\").pop();
    $(this).parents(".rounded_block").find('.form-control').attr('placeholder', fileInputContent);
  })

  

  var optionsAutocomplete = {
    data: ["Design", "Design", "Design"]
  };
  $("#team").easyAutocomplete(optionsAutocomplete);
  $("#user").easyAutocomplete(optionsAutocomplete);
  $("#categories").easyAutocomplete(optionsAutocomplete);

})


function detectOutdatedBrowser(){
  outdatedBrowser({ 
    bgColor: '#f25648', 
    color: '#ffffff',
    lowerThan: 'transform' // 'IE9'
  });
}

function openFilters(){
  $('.open_filters_field').on('click', function() {
    $('.filters_bot').slideDown();
  });
}

function hideFilters(){
  $(document).mouseup(function (e) {
    var container = $(".filters_block, .datepicker, .search_table .calendar");

    if (!container.is(e.target) 
        && container.has(e.target).length === 0) 
    {
        container.find('.filters_bot').slideUp();
    }
  });
}

 function hoverIcon(){
  $('.table_image').hover(function () {
    var link = $(this);
    var src = link.attr("data-src");
    link.data('linkText', link.html());
    link.append('<span class="img_holder"><span class="inner"><img src=\"'+src+'\" alt=""></span></span>');
  }, function () {
    $('.img_holder', $(this)).remove();
  });
}

function removeInfoMsg(){
  $('.info_msg .icon_close').click(function() {
    $(this).parent().fadeTo("normal", 0.01, function(){ 
      $(this).remove();
    });
  });
}



