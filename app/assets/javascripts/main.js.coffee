@loadDetail = ->
  jQuery.ajax({
          dataType: 'script',
          type:     'post',
          url:      "/detail"
        });