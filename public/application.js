$(document).ready(function() {
  $(document).on('click', 'form#hit_form input', function() {
    $.ajax({
      type: 'POST',
      url: '/hit'
    }).done(function(msg) {
      $('div#whole').replaceWith(msg); //this replaces the 'whole' div with HTML returned by AJAX response
    });

    return false;
  });

  $(document).on('click', 'form#stay_form input', function() {
    $.ajax({
      type: 'POST',
      url: '/stay'
    }).done(function(msg) {
      $('div#whole').replaceWith(msg);
    });

    return false;    
  });

  $(document).on('click', 'form#dealer_hit_form', function() {
    $.ajax({
      type: 'POST',
      url: '/dealer_add_card'
    }).done(function(msg){
      $('div#whole').replaceWith(msg);
    });

    return false;
  });
});
