@loadDetail = (category, quantities, terms) ->
  jQuery.ajax({
          dataType: 'script',
          type:     'get',
          url:      "/detail",
		  data:     {
			  			'category': category,
			  			'quantities': quantities,
						'terms': terms
		  			}
        });