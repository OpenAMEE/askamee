require 'spec_helper'

describe QuestionController do
  describe "GET answer" do
    
    it "assigns quantities" do
      get :answer, :q => 'shipping 10 tonnes of stuff for 1000 kilometres'
      assigns(:quantities).map{|x| x.to_s}.should eql ['10.0 t', '1000.0 km']
    end

    it "assigns terms" do
      get :answer, :q => 'shipping 10 tonnes of stuff for 1000 kilometres'
      assigns(:terms).should eql ['shipping', 'stuff']
    end

    it "assigns categories" do
      get :answer, :q => 'shipping 10 tonnes of stuff for 1000 kilometres'
      assigns(:categories).should eql [ "Ship_Freight_Defra", 
                                        "Etching_and_CVD_cleaning_in_the_Electronics_Industry", 
                                        "Ship_generic_Defra", 
                                        "DEFRA_methodologies_for_transport", 
                                        "DEFRA_freight_transport_methodology", 
                                        "Other_regional_ship_freight", 
                                        "Freight_transport_by_Greenhouse_Gas_Protocol" ]
    end

    it "assigns a thinking message" do
      get :answer, :q => 'shipping 10 tonnes of stuff for 1000 kilometres'
      assigns(:message).should_not be_blank
    end


  end
end