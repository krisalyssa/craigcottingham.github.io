module Jekyll
  class FootnoteTag < Liquid::Block
    
    def initialize(tag_name, markup, tokens)
      @ref = markup.strip
      super
    end
    
    def render(context)
      context["footnotes"] ||= []
      context["footnotes"] << [ @ref, render_all(@nodelist, context).flatten.join(' ') ]
      %Q(<a id="fnr-#{@ref}" href="#fn-#{@ref}">(#{@ref})</a>)
    end
    
  end
end

Liquid::Template.register_tag('fn', Jekyll::FootnoteTag)
