require 'spec_helper'

describe BatchController do
  before do
    GenericFile.any_instance.stubs(:terms_of_service).returns('1')
    @user = FactoryGirl.find_or_create(:user)
    sign_in @user
    User.any_instance.stubs(:groups).returns([])
    controller.stubs(:clear_session_user) ## Don't clear out the authenticated session
  end
  describe "#update" do
    before do
      @batch = Batch.new
      @batch.save
      @file = GenericFile.new(:batch=>@batch)
      @file.apply_depositor_metadata(@user.login)
      @file.save
      @file2 = GenericFile.new(:batch=>@batch)
      @file2.apply_depositor_metadata('otherUser')
      @file2.save
    end
    after do
      @batch.delete
      @file.delete
      @file2.delete
    end
    it "should check permissions for each file before updating" do
      controller.expects(:permissions_solr_doc_for_id).times(2).returns("mock solr permissions")
      controller.expects(:can?).with(:read, "mock solr permissions").times(2)
      post :update, :id=>@batch.pid, "generic_file"=>{"terms_of_service"=>"1", "read_groups_string"=>"", "read_users_string"=>"archivist1, archivist2", "tag"=>[""]} 
    end
    describe "when user has edit permissions on a file" do
      it "should set the users with read access" do
        post :update, :id=>@batch.pid, "generic_file"=>{"terms_of_service"=>"1", "read_groups_string"=>"", "read_users_string"=>"archivist1, archivist2", "tag"=>[""]} 
        file = GenericFile.find(@file.pid)
        file.read_users.should == ['archivist1', 'archivist2']

        response.should redirect_to dashboard_path
      end
      it "should set the groups with read access" do
        post :update, :id=>@batch.pid, "generic_file"=>{"terms_of_service"=>"1", "read_groups_string"=>"group1, group2", "read_users_string"=>"", "tag"=>[""]} 
        file = GenericFile.find(@file.pid)
        file.read_groups.should == ['group1', 'group2']
      end
      it "should set public read access" do
        post :update, :id=>@batch.pid, "permission"=>{"group"=>{"public"=>"read"}}, "generic_file"=>{"terms_of_service"=>"1", "read_groups_string"=>"", "read_users_string"=>"", "tag"=>[""]}
        file = GenericFile.find(@file.pid)
        file.read_groups.should == ['public']
      end
      it "should set public read access and groups at the same time" do
        post :update, :id=>@batch.pid, "permission"=>{"group"=>{"public"=>"read"}}, "generic_file"=>{"terms_of_service"=>"1", "read_groups_string"=>"group1, group2", "read_users_string"=>"", "tag"=>[""]}
        file = GenericFile.find(@file.pid)
        file.read_groups.should == ['group1', 'group2', 'public']
      end
      it "should set public discover access and groups at the same time" do
        post :update, :id=>@batch.pid, "permission"=>{"group"=>{"public"=>"discover"}}, "generic_file"=>{"terms_of_service"=>"1", "read_groups_string"=>"group1, group2", "read_users_string"=>"", "tag"=>[""]}
        file = GenericFile.find(@file.pid)
        file.read_groups.should == ['group1', 'group2']
        file.discover_groups.should == ['public']
      end
      it "should set metadata like title" do
        post :update, :id=>@batch.pid, "generic_file"=>{"terms_of_service"=>"1", "tag"=>["footag", "bartag"], "title"=>"New Title"} 
        file = GenericFile.find(@file.pid)
        file.title.should == ["New Title"]
        file.tag.should == ["footag", "bartag"]
      end

      it "should not set any tags" do
        post :update, :id=>@batch.pid, "generic_file"=>{"terms_of_service"=>"1", "read_groups_string"=>"", "read_users_string"=>"archivist1", "tag"=>[""]} 
        file = GenericFile.find(@file.pid)
        file.tag.should be_empty
      end
    end

    describe "when user does not have edit permissions on a file" do
      it "should not modify the object" do
        file = GenericFile.find(@file2.pid)
        file.title = "Original Title"
        file.read_groups.should == []
        file.save
        post :update, :id=>@batch.pid, "generic_file"=>{"terms_of_service"=>"1", "read_groups_string"=>"group1, group2", "read_users_string"=>"", "tag"=>[""], "title"=>"New Title"} 
        file = GenericFile.find(@file2.pid)
        file.title.should == ["Original Title"]
        file.read_groups.should == []
      end
    end
  end
end
