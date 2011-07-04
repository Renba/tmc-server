require 'spec_helper'

=begin

# This spec was generated by rspec-rails when you ran the scaffold generator.
# It demonstrates how one might use RSpec to specify the controller code that
# was generated by Rails when you ran the scaffold generator.
#
# It assumes that the implementation code is generated by the rails scaffold
# generator.  If you are using any extension libraries to generate different
# controller code, this generated spec may or may not pass.
#
# It only uses APIs available in rails and/or rspec-rails.  There are a number
# of tools you can use to make these specs even more expressive, but we're
# sticking to rails and rspec-rails APIs to keep things simple and stable.
#
# Compared to earlier versions of this generator, there is very limited use of
# stubs and message expectations in this spec.  Stubs are only used when there
# is no simpler way to get a handle on the object needed for the example.
# Message expectations are only used when there is no simpler way to specify
# that an instance is receiving a specific message.

describe TestSuiteRunsController do

  # This should return the minimal set of attributes required to create a valid
  # TestSuiteRun. As you add validations to TestSuiteRun, be sure to
  # update the return value of this method accordingly.
  def valid_attributes
    {}
  end

  describe "GET index" do
    it "assigns all test_suite_runs as @test_suite_runs" do
      test_suite_run = TestSuiteRun.create! valid_attributes
      get :index
      assigns(:test_suite_runs).should eq([test_suite_run])
    end
  end

  describe "GET show" do
    it "assigns the requested test_suite_run as @test_suite_run" do
      test_suite_run = TestSuiteRun.create! valid_attributes
      get :show, :id => test_suite_run.id.to_s
      assigns(:test_suite_run).should eq(test_suite_run)
    end
  end

  describe "GET new" do
    it "assigns a new test_suite_run as @test_suite_run" do
      get :new
      assigns(:test_suite_run).should be_a_new(TestSuiteRun)
    end
  end

  describe "GET edit" do
    it "assigns the requested test_suite_run as @test_suite_run" do
      test_suite_run = TestSuiteRun.create! valid_attributes
      get :edit, :id => test_suite_run.id.to_s
      assigns(:test_suite_run).should eq(test_suite_run)
    end
  end

  describe "POST create" do
    describe "with valid params" do
      it "creates a new TestSuiteRun" do
        expect {
          post :create, :test_suite_run => valid_attributes
        }.to change(TestSuiteRun, :count).by(1)
      end

      it "assigns a newly created test_suite_run as @test_suite_run" do
        post :create, :test_suite_run => valid_attributes
        assigns(:test_suite_run).should be_a(TestSuiteRun)
        assigns(:test_suite_run).should be_persisted
      end

      it "redirects to the created test_suite_run" do
        post :create, :test_suite_run => valid_attributes
        response.should redirect_to(TestSuiteRun.last)
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved test_suite_run as @test_suite_run" do
        # Trigger the behavior that occurs when invalid params are submitted
        TestSuiteRun.any_instance.stub(:save).and_return(false)
        post :create, :test_suite_run => {}
        assigns(:test_suite_run).should be_a_new(TestSuiteRun)
      end

      it "re-renders the 'new' template" do
        # Trigger the behavior that occurs when invalid params are submitted
        TestSuiteRun.any_instance.stub(:save).and_return(false)
        post :create, :test_suite_run => {}
        response.should render_template("new")
      end
    end
  end

  describe "PUT update" do
    describe "with valid params" do
      it "updates the requested test_suite_run" do
        test_suite_run = TestSuiteRun.create! valid_attributes
        # Assuming there are no other test_suite_runs in the database, this
        # specifies that the TestSuiteRun created on the previous line
        # receives the :update_attributes message with whatever params are
        # submitted in the request.
        TestSuiteRun.any_instance.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, :id => test_suite_run.id, :test_suite_run => {'these' => 'params'}
      end

      it "assigns the requested test_suite_run as @test_suite_run" do
        test_suite_run = TestSuiteRun.create! valid_attributes
        put :update, :id => test_suite_run.id, :test_suite_run => valid_attributes
        assigns(:test_suite_run).should eq(test_suite_run)
      end

      it "redirects to the test_suite_run" do
        test_suite_run = TestSuiteRun.create! valid_attributes
        put :update, :id => test_suite_run.id, :test_suite_run => valid_attributes
        response.should redirect_to(test_suite_run)
      end
    end

    describe "with invalid params" do
      it "assigns the test_suite_run as @test_suite_run" do
        test_suite_run = TestSuiteRun.create! valid_attributes
        # Trigger the behavior that occurs when invalid params are submitted
        TestSuiteRun.any_instance.stub(:save).and_return(false)
        put :update, :id => test_suite_run.id.to_s, :test_suite_run => {}
        assigns(:test_suite_run).should eq(test_suite_run)
      end

      it "re-renders the 'edit' template" do
        test_suite_run = TestSuiteRun.create! valid_attributes
        # Trigger the behavior that occurs when invalid params are submitted
        TestSuiteRun.any_instance.stub(:save).and_return(false)
        put :update, :id => test_suite_run.id.to_s, :test_suite_run => {}
        response.should render_template("edit")
      end
    end
  end

  describe "DELETE destroy" do
    it "destroys the requested test_suite_run" do
      test_suite_run = TestSuiteRun.create! valid_attributes
      expect {
        delete :destroy, :id => test_suite_run.id.to_s
      }.to change(TestSuiteRun, :count).by(-1)
    end

    it "redirects to the test_suite_runs list" do
      test_suite_run = TestSuiteRun.create! valid_attributes
      delete :destroy, :id => test_suite_run.id.to_s
      response.should redirect_to(test_suite_runs_url)
    end
  end

end

=end
