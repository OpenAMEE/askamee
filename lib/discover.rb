module AMEE

  module Discover

    def discover_url(category, item = nil, pi = nil)
      link = "http://discover.amee.com/categories/#{@category.meta.wikiname}"
      if item
        drills = item.label.split(", ")
        drills = drills.map{|x| URI.escape(x,/\//)}.map{|x| URI.escape(x)}
        link += "/data/#{drills.join('/')}"
        if pi && pi.total_amount.to_f > 0.0
          values = category.profile_ivds.map{|x|x.path}.map do |ppath|
            val = pi.find_input_value(ppath)
            str = 'none'
            if val && val[:value].present?
              str = val[:value]
              unit = pi.find_input_value(ppath+"Unit")[:value] rescue nil
              per_unit = pi.find_input_value(ppath+"PerUnit")[:value] rescue nil
              if (unit && !unit.blank?) || (per_unit && !per_unit.blank?)
                str += ";"
                str += unit if (unit && !unit.blank?)
                str += ";#{per_unit}" if (per_unit && !per_unit.blank?)
              end
            end
            str
          end
          link += "/result/#{values.join('/')}"
        else
          link += "/calculator"
        end
      end
      link
    end

  end

end
