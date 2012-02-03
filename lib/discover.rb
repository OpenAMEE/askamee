module AMEE

  module Discover

    def discover_url(category, item, pi = nil)
      drills = item.label.split(", ")
      drills = drills.map{|x| URI.escape(x,/\//)}.map{|x| URI.escape(x)}
      link = "http://discover.amee.com/categories/#{@category.meta.wikiname}/data/#{drills.join('/')}"
      if pi && pi.total_amount.to_f > 0.0
        values = category.profile_ivds.map{|x|x.path}.map do |ppath|
          val = pi.find_value(ppath)
          str = 'none'
          if val && val[:value].present?
            str = val[:value]
            unit = val[:unit]
            per_unit = val[:per_unit]
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
      link
    end

  end

end
