module AMEE

  module Data

    class Category

      def profile_ivds
        ivds.select{|x| x.profile? && x.versions.any?{|y| y=~/2/}}
      end

      def ivds
        @ivds ||= Proc.new {
          item_definition ? item_definition.item_value_definition_list.sort{|a,b| a.path<=>b.path} : []
        }.call
      end

    end
    
    class Item
      
      def find_input_value(path)
        choices.find{ |x| x[:name] == path}
      end
      
    end

  end

end
