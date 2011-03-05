module Jekyll
  class AllFootnotesTag < Liquid::Tag
    safe true
    
    def initialize(tag_name, markup, tokens)
      @ref = markup.strip
      super
    end
    
    def render(context)
      return 'no footnotes' if (context["footnotes"].nil? || context["footnotes"].empty?)

      result = <<-END_OF_MARKUP
<div class="footnotes">
  <h2>Footnotes</h2>
  <ol>
      END_OF_MARKUP
      
      context["footnotes"].each { | ref, markup |
        result << %Q(<li id="fn-#{ref}"><p>#{markup}&nbsp;<a href="#fnr-#{ref}" class="fn-backlink" title="Jump back to footnote '#{ref}'.">&#8617;</a></p></li>)
        result << "\n"
      }
      result << <<-END_OF_MARKUP
  </ol>
</div>
      END_OF_MARKUP

      result
    end
    
  end
end

Liquid::Template.register_tag('fns', Jekyll::AllFootnotesTag)
