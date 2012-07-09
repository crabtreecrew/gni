$ ->
  $('#advanced_options').bind 'click', (e) =>
    e.preventDefault();
    $('#advanced_selections').toggle();