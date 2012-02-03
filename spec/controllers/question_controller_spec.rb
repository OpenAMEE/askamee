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
      assigns(:categories).should eql [ "Etching_and_CVD_cleaning_in_the_Electronics_Industry", 
                                        "DEFRA_freight_transport_methodology", 
                                        "Freight_transport_by_Greenhouse_Gas_Protocol" ]
    end

    it "assigns a thinking message" do
      get :answer, :q => 'shipping 10 tonnes of stuff for 1000 kilometres'
      assigns(:message).should_not be_blank
    end


  end

  describe "GET detail" do

    it "gets results with a single input quantity" do
      get :detailed_answer, :quantities => '100.0 km', :terms => 'truck', :category => 'Generic_van_transport'
      assigns(:pi).should_not be_nil
      assigns(:pi).total_amount.should eql 27.18
      assigns(:more_info_url).should eql 'http://discover.amee.com/categories/Generic_van_transport/data/cng/up%20to%203.5%20tonnes/result/false/true/none/100.0;km/false/none/0/-1/0/true/false/false'
    end
    
  end


end