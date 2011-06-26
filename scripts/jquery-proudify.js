/*
	jquery-proudify.js
	
	Mihail Szabolcs
	Copyright (c) 2011
	
	Live @ http://status.szabster.net/
*/
(function($)
{
	var VERSION = [0,1,0];

	var GitHub = function(element, settings)
	{
		this.element = element;
		this.settings = settings;
		this.init();
	};
	GitHub.prototype = 
	{
		element : false,
		settings : {},
		repositories : [],
		wrapper : false,
		list : false,
		loading : false,
		init : function()
		{
			this.wrapper = $('<div>').
							addClass('proudify github').
							appendTo(this.element);

			this.list = $('<ul>').
							addClass('list').
							appendTo(this.wrapper);

			this.loading = $('<li>').
							addClass('item loading').
							html('<span class="desc">Loading ...</span>').
							appendTo(this.list);
	
			this.fetch('https://api.github.com/users/' + this.settings.username + '/repos?callback=?');
		},
		fetch : function(url)
		{
			var self = this;
			$.getJSON(url, function(result)
			{
				for(var i in result.data)
					self.repositories.push(result.data[i]);
					
				if(result.meta['Link'][0][1]['rel'] == 'first')
				{
					self.render();
				}
				else
				{
					self.fetch(result.meta['Link'][0][0]+'&callback=?');
				}
			});
		},
		toDate : function(str)
		{
		  return new Date(str.substring(0,4), str.substring(5,7), str.substring(8,10)).getTime();
		},
		render : function()
		{
			var cutoff_date = new Date();
			cutoff_date.setDate(new Date().getDate() - this.settings.pushed_at);
			cutoff_date = cutoff_date.getTime();
			
			this.loading.remove();
			
			var self = this;

			$.each(this.repositories.sort(
			function(a, b)
			{
				return new Date(b.pushed_at).getTime() - new Date(a.pushed_at).getTime();
			}),
			function(i, item) 
			{
				if(item.fork == true && self.settings.forks == false)
				{
					return;
				}
				
				var li = $('<li>').addClass('item').appendTo(self.list);
				
				$('<a>').
				attr('href', item.html_url).
				attr('target', '_blank').
				html(item.name).
				appendTo(li);

				$('<span>').addClass('desc').html(item.description).appendTo(li);
				
        // var year = item.pushed_at.substring(0,4);
        // var month = item.pushed_at.substring(5,7);
        // var day = item.pushed_at.substring(8,10);
        // var pushed_at = new Date(year, month, day).getTime();
        var pushed_at = this.toDate(item.pushed_at);
				if(pushed_at > cutoff_date)
				{
					$('<span>').addClass('status green').html('ONGOING').appendTo(li);
				}
				else
				{
					$('<span>').addClass('status red').html('ON HOLD').appendTo(li);
				}
			});
		}
	};
	
	var CoderWall = function(element, settings)
	{
		this.element = element;
		this.settings = settings;
		this.init();
	};
	CoderWall.prototype = 
	{
		element : false,
		settings : {},
		badges : [],
		wrapper : false,
		list : false,
		loading : false,
		init : function()
		{
			this.wrapper = $('<div>').
							addClass('proudify coderwall').
							appendTo(this.element);

			this.list = $('<ul>').
							addClass('list').
							appendTo(this.wrapper);

			this.loading = $('<li>').
							addClass('item loading').
							html('<span class="desc">Loading ...</span>').
							appendTo(this.list);
	
			this.fetch('http://coderwall.com/' + this.settings.username + '.json?callback=?');
		},
		fetch : function(url)
		{
			var self = this;
			$.getJSON(url, function(result)
			{
				for(var i in result.data.badges)
					self.badges.push(result.data.badges[i]);
					
				self.render();
			});
		},
		render : function()
		{
			this.loading.remove();
			
			var self = this;

			$.each(this.badges,function(i, item) 
			{
				var li = $('<li>').addClass('item').appendTo(self.list);
				var link = $('<a>').
				attr('href', 'http://coderwall.com/' + self.settings.username).
				attr('target', '_blank').
				appendTo(li);

				$('<img>').
				attr('alt', item.name).
				attr('title', item.description).
				attr('src', item.badge).
				appendTo(link);
			});

			$('<div>').css('clear','both').appendTo(this.list);
		}
	};
	
	$.fn.proudify = function(options) 
	{
		var services = 
		{
			github : GitHub,
			coderwall : CoderWall
		};
		
		var settings = $.extend({}, 
        						{ 
        							username: false, 
        							service: 'github',
        							pushed_at: 120, 
        							forks: false,
        							devel: false
        						},
       							options || {});

      	if(settings.username && (settings.service in services))
      	{
			new services[settings.service](this, settings);
		}
      	      	
		return this;
	};
})(jQuery);
