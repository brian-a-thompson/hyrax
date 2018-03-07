function launch_confirm() {
  var url = document.location.toString();
  if (url.match('content_blocks')) {
    var confirm_msg = confirm('Are you sure you want to leave this tab?  Any unsaved data will be lost.');
    if (confirm_msg === true) {
       $(this).tab('show');
    } else {
     return false;
    }
  }
}

Blacklight.onLoad(function() {
  // hide the editor initially
  $('[data-behavior="reveal-editor"]').each(function(){$($(this).data('target')).hide();});

  // Show the form, hide the preview
  $('[data-behavior="reveal-editor"]').on('click', function(evt) {
    evt.preventDefault();
    $this = $(this);
    $this.parent().hide();
    $($this.data('target')).show();
  });

  $('a[data-toggle="tab"]').on('click', function(evt) {
    evt.preventDefault();
    return launch_confirm();
  });  
});