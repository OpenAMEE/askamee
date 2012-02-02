module Thesaurus

  def thesaurus_expand(query,inflect=true)
    terms=CSV::parse_line(query,' ') # so that quoted strings aren't tokenized
    terms = terms.map{|x| x.singularize}
    finalterms=[]
    terms.each do |term|
      next unless term
      logicsymbol=term.slice(0,1)
      if (logicsymbol=~/[\+\-]/)
        lterm=term.slice(1,term.length)
      else
        lterm=term.to_s
        logicsymbol=nil
      end
      expanded=[lterm]
      THESAURUS.each do |synonym_list|
        # assume synonym lists disjoint.
        # otherwise will end up with the original term multiple times
        if synonym_list.include?(lterm)
          expanded.concat synonym_list-[lterm]
        end
      end
      aexpanded=expanded.clone
      aexpanded.each do |e|
        expanded<<e.pluralize unless e.pluralize==e if inflect
        expanded<<e.singularize unless e.singularize==e if inflect
      end
      finalterms.push(restorelogic(logicsymbol,expanded))
    end
    finalterms.join(' ')
  end
  
  def restorelogic(operator,terms)
      return terms.join(" ") if operator==nil
      return "+(#{terms.join(" ")})" if operator=="+"&&terms.length>1
      return "+#{terms.first}" if operator=="+"
      return "-#{terms.join(" -")}" if operator=="-"
  end

end