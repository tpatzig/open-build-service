# encoding: UTF-8
require File.expand_path(File.dirname(__FILE__) + "/..") + "/test_helper"
require 'source_controller'

class SourceControllerTest < ActionController::IntegrationTest 
  fixtures :all
  
  def test_get_projectlist
    prepare_request_with_user "tom", "thunder"
    get "/source"
    assert_response :success
    assert_tag :tag => "directory", :child => { :tag => "entry" }
    assert_tag :tag => "directory",
      :children => { :only => { :tag => "entry" } }
  end

  def test_get_projectlist_with_hidden_project
    prepare_request_with_user "tom", "thunder"
    get "/source"
    assert_response :success 
    assert_no_match(/entry name="HiddenProject"/, @response.body)
    #retry with maintainer
    ActionController::IntegrationTest::reset_auth
    prepare_request_with_user "adrian", "so_alone"
    get "/source"
    assert_response :success 
    assert_match(/entry name="HiddenProject"/, @response.body)
  end

  def test_get_projectlist_with_sourceaccess_protected_project
    prepare_request_with_user "tom", "thunder"
    get "/source"
    assert_response :success 
    assert_match(/entry name="SourceprotectedProject"/, @response.body)
    #retry with maintainer
    ActionController::IntegrationTest::reset_auth
    prepare_request_with_user "adrian", "so_alone"
    get "/source"
    assert_response :success 
    assert_match(/entry name="SourceprotectedProject"/, @response.body)
  end


  def test_get_packagelist
    prepare_request_with_user "tom", "thunder"
    get "/source/kde4"
    assert_response :success
    assert_tag :tag => "directory", :child => { :tag => "entry" }
    assert_tag :tag => "directory",
      :children => { :count => 2, :only => { :tag => "entry" } }
  end

  def test_get_packagelist_with_hidden_project
    prepare_request_with_user "tom", "thunder"
    get "/source/HiddenProject"
    assert_response 404
    assert_match(/unknown_project/, @response.body)
    #retry with maintainer
    ActionController::IntegrationTest::reset_auth
    prepare_request_with_user "adrian", "so_alone"
    get "/source/HiddenProject"
    assert_response :success 
    assert_tag :tag => "directory", :child => { :tag => "entry" }
    assert_tag :tag => "directory",
      :children => { :count => 3, :only => { :tag => "entry" } }
    assert_match(/entry name="pack"/, @response.body)
    assert_match(/entry name="target"/, @response.body)
  end

  def test_get_packagelist_with_sourceprotected_project
    prepare_request_with_user "tom", "thunder"
    get "/source/SourceprotectedProject"
    assert_response :success 
    assert_tag :tag => "directory", :child => { :tag => "entry" }
    assert_tag :tag => "directory",
      :children => { :count => 2 }
    assert_match(/entry name="target"/, @response.body)
    #retry with maintainer
    ActionController::IntegrationTest::reset_auth
    prepare_request_with_user "adrian", "so_alone"
    get "/source/SourceprotectedProject"
    assert_response :success 
    assert_tag :tag => "directory", :child => { :tag => "entry" }
    assert_tag :tag => "directory",
      :children => { :count => 2, :only => { :tag => "entry" } }
    assert_match(/entry name="pack"/, @response.body)
    assert_match(/entry name="target"/, @response.body)
  end

  # non-existing project should return 404
  def test_get_illegal_project
    prepare_request_with_user "tom", "thunder"
    get "/source/kde2000/_meta"
    assert_response 404
  end


  # non-existing project-package should return 404
  def test_get_illegal_projectfile
    prepare_request_with_user "tom", "thunder"
    get "/source/kde4/kdelibs2000/_meta"
    assert_response 404
  end

  def test_use_illegal_encoded_parameters
    prepare_request_with_user "king", "sunflower"
    put "/source/kde4/kdelibs/DUMMY?comment=working%20with%20Umläut", "WORKING"
    assert_response :success
    put "/source/kde4/kdelibs/DUMMY?comment=illegalchar#{0x96.chr}#{0x96.chr}asd", "NOTWORKING"
    assert_response 400
    assert_tag :tag => "status", :attributes => { :code => "invalid_text_encoding" }
  end

  def test_get_project_meta
    prepare_request_with_user "tom", "thunder"
    get "/source/kde4/_meta"
    assert_response :success
    assert_tag :tag => "project", :attributes => { :name => "kde4" }
  end

  def test_get_project_meta_from_hidden_project
    prepare_request_with_user "tom", "thunder"
    get "/source/HiddenProject/_meta"
    assert_response 404
    assert_match(/unknown_project/, @response.body)
    #retry with maintainer
    ActionController::IntegrationTest::reset_auth
    prepare_request_with_user "adrian", "so_alone"
    get "/source/HiddenProject/_meta"
    assert_response :success
    assert_tag :tag => "project", :attributes => { :name => "HiddenProject" }
  end

  def test_get_project_meta_from_sourceaccess_protected_project
    prepare_request_with_user "tom", "thunder"
    get "/source/SourceprotectedProject/_meta"
    assert_response :success
    assert_tag :tag => "project", :attributes => { :name => "SourceprotectedProject" }
    #retry with maintainer
    ActionController::IntegrationTest::reset_auth
    prepare_request_with_user "sourceaccess_homer", "homer"
    get "/source/SourceprotectedProject/_meta"
    assert_response :success
    assert_tag :tag => "project", :attributes => { :name => "SourceprotectedProject" }
  end

  def test_get_package_filelist
    prepare_request_with_user "tom", "thunder"
    get "/source/kde4/kdelibs"
    assert_response :success
    assert_tag :tag => "directory", :child => { :tag => "entry" }
    assert_tag :tag => "directory",
      :children => { :count => 1, :only => { :tag => "entry", :attributes => { :name => "my_patch.diff" } } }
 
    # now testing if also others can see it
    prepare_request_with_user "Iggy", "asdfasdf"
    assert_response :success
    assert_tag :tag => "directory", :child => { :tag => "entry" }
    assert_tag :tag => "directory",
      :children => { :count => 1, :only => { :tag => "entry", :attributes => { :name => "my_patch.diff" } } }

  end

  def test_get_package_filelist_from_hidden_project
    prepare_request_with_user "tom", "thunder"
    get "/source/HiddenProject/pack"
    assert_response 404
    assert_tag :tag => "status", :attributes => { :code => "unknown_project" }
    #retry with maintainer
    ActionController::IntegrationTest::reset_auth
    prepare_request_with_user "adrian", "so_alone"
    get "/source/HiddenProject/pack"
    assert_response :success
    assert_tag :tag => "directory", :child => { :tag => "entry" }
    assert_tag :tag => "directory",
      :children => { :count => 2 }
  end

  def test_get_package_filelist_from_sourceaccess_protected_project
    prepare_request_with_user "tom", "thunder"
    get "/source/SourceprotectedProject/pack"
    assert_response 403
    #retry with maintainer
    ActionController::IntegrationTest::reset_auth
    prepare_request_with_user "sourceaccess_homer", "homer"
    get "/source/SourceprotectedProject/pack"
    assert_response :success
    assert_tag :tag => "directory", :child => { :tag => "entry" }
    assert_tag :tag => "directory",
      :children => { :count => 2 }
  end

  def test_get_package_meta
    prepare_request_with_user "tom", "thunder"
    get "/source/kde4/kdelibs/_meta"
    assert_response :success
    assert_tag :tag => "package", :attributes => { :name => "kdelibs" }
  end

  def test_get_package_meta_from_hidden_project
    prepare_request_with_user "tom", "thunder"
    get "/source/HiddenProject/pack/_meta"
    assert_response 404
    assert_tag :tag => "status", :attributes => { :code => "unknown_project" }
    #retry with maintainer
    ActionController::IntegrationTest::reset_auth
    prepare_request_with_user "adrian", "so_alone"
    get "/source/HiddenProject/pack/_meta"
    assert_response :success
    assert_tag :tag => "package", :attributes => { :name => "pack" , :project => "HiddenProject"}
  end

  def test_get_package_meta_from_sourceacces_protected_project
    # package meta is visible
    prepare_request_with_user "tom", "thunder"
    get "/source/SourceprotectedProject/pack/_meta"
    assert_response :success
    assert_tag :tag => "package", :attributes => { :name => "pack" , :project => "SourceprotectedProject"}
    # retry with maintainer
    ActionController::IntegrationTest::reset_auth
    prepare_request_with_user "sourceaccess_homer", "homer"
    get "/source/SourceprotectedProject/pack/_meta"
    assert_response :success
    assert_tag :tag => "package", :attributes => { :name => "pack" , :project => "SourceprotectedProject"}
  end

  def test_invalid_project_and_package_name
    prepare_request_with_user "king", "sunflower"
    [ "..", "_blah" ].each do |n|
      put "/source/#{n}/_meta", "<project name='#{n}'> <title /> <description /> </project>"
      assert_response 400
      put "/source/kde4/#{n}/_meta", "<package project='kde4' name='#{n}'> <title /> <description /> </project>"
      assert_response 400
      post "/source/kde4/kdebase", :cmd => "branch", :target_package => n
      assert_response 400
      post "/source/kde4/#{n}", :cmd => "copy", :opackage => "kdebase", :oproject => "kde4"
      if n == ".."
        # this is failing already at routing
        assert_response 403
      else
        assert_response 400
      end
    end
  end

  # project_meta does not require auth
  def test_invalid_user
    prepare_request_with_user "king123", "sunflower"
    get "/source/kde4/_meta"
    assert_response 401
  end
  
  def test_valid_user
    prepare_request_with_user "tom", "thunder"
    get "/source/kde4/_meta"
    assert_response :success
  end

  
  def test_put_project_meta_with_invalid_permissions
    prepare_request_with_user "tom", "thunder"
    # The user is valid, but has weak permissions
    
    # Get meta file
    get "/source/kde4/_meta"
    assert_response :success

    # Change description
    xml = @response.body
    new_desc = "Changed description"
    doc = REXML::Document.new( xml )
    d = doc.elements["//description"]
    d.text = new_desc

    # Write changed data back
    put url_for(:controller => :source, :action => :project_meta, :project => "kde4"), doc.to_s
    assert_response 403

    # admin only tag    
    d = doc.elements["/project"]
    d = d.add_element "remoteurl"
    d.text = "http://localhost:5352"
    prepare_request_with_user "fred", "geröllheimer"
    put url_for(:controller => :source, :action => :project_meta, :project => "kde4"), doc.to_s
    assert_response 403
    assert_match(/admin rights are required to change remoteurl/, @response.body)

    # invalid xml
    put url_for(:controller => :source, :action => :project_meta, :project => "NewProject"), "<asd/>"
    assert_response 400
    assert_match(/validation error/, @response.body)

    # new project
    put url_for(:controller => :source, :action => :project_meta, :project => "NewProject"), "<project name='NewProject'><title>blub</title><description/></project>"
    assert_response 403
    assert_match(/not allowed to create new project/, @response.body)

    prepare_request_with_user "king", "sunflower"
    put url_for(:controller => :source, :action => :project_meta, :project => "_NewProject"), "<project name='_NewProject'><title>blub</title><description/></project>"
    assert_response 400
    assert_match(/projid '_NewProject' is illegal/, @response.body)
  end


  def test_put_project_meta
    prj="kde4"      # project
    resp1=:success  # expected response 1 & 2
    resp2=:success  # \/ expected assert
    aresp={:tag => "status", :attributes => { :code => "ok" } }
    match=true      # value written matches 2nd read
    # admin
    prepare_request_with_user "king", "sunflower"
    do_change_project_meta_test(prj, resp1, resp2, aresp, match)
    # maintainer 
    prepare_request_with_user "fred", "geröllheimer"
    do_change_project_meta_test(prj, resp1, resp2, aresp, match)
    # maintainer via group
    prepare_request_with_user "adrian", "so_alone"
    do_change_project_meta_test(prj, resp1, resp2, aresp, match)

    # check history
    get "/source/kde4/_project/_history?meta=1"
    assert_response :success
    assert_tag( :tag => "revisionlist" )
    assert_tag( :tag => "user", :content => "adrian" )
  end

  def test_create_subproject
    subprojectmeta="<project name='kde4:subproject'><title></title><description/></project>"

    # nobody
    ActionController::IntegrationTest::reset_auth 
    put url_for(:controller => :source, :action => :project_meta, :project => "kde4:subproject"), subprojectmeta
    assert_response 401
    prepare_request_with_user "tom", "thunder"
    put url_for(:controller => :source, :action => :project_meta, :project => "kde4:subproject"), subprojectmeta
    assert_response 403
    # admin
    prepare_request_with_user "king", "sunflower"
    put url_for(:controller => :source, :action => :project_meta, :project => "kde4:subproject"), subprojectmeta
    assert_response :success
    delete "/source/kde4:subproject"
    assert_response :success
    # maintainer 
    prepare_request_with_user "fred", "geröllheimer"
    put url_for(:controller => :source, :action => :project_meta, :project => "kde4:subproject"), subprojectmeta
    assert_response :success
    delete "/source/kde4:subproject"
    assert_response :success
    # maintainer via group
    prepare_request_with_user "adrian", "so_alone"
    put url_for(:controller => :source, :action => :project_meta, :project => "kde4:subproject"), subprojectmeta
    assert_response :success
    delete "/source/kde4:subproject"
    assert_response :success

    # create illegal project 
    prepare_request_with_user "fred", "geröllheimer"
    subprojectmeta="<project name='kde4_subproject'><title></title><description/></project>"
    put url_for(:controller => :source, :action => :project_meta, :project => "kde4:subproject"), subprojectmeta
    assert_response 400
    aresp={:tag => "status", :attributes => { :code => "project_name_mismatch" } }
  end

  def test_put_project_meta_hidden_project
    prj="HiddenProject"
    # uninvolved user
    resp1=404
    resp2=nil
    aresp=nil
    match=nil
    prepare_request_with_user "tom", "thunder"
    do_change_project_meta_test(prj, resp1, resp2, aresp, match)
    # admin
    resp1=:success
    resp2=:success
    aresp={:tag => "status", :attributes => { :code => "ok" } }
    match=true
    prepare_request_with_user "king", "sunflower"
    do_change_project_meta_test(prj, resp1, resp2, aresp, match)
    # maintainer
    prepare_request_with_user "hidden_homer", "homer"
    do_change_project_meta_test(prj, resp1, resp2, aresp, match)
    # FIXME: maintainer via group
  end

  def test_put_project_meta_sourceaccess_protected_project
    prj="SourceprotectedProject"
    # uninvolved user - can't change meta
    resp1=:success
    resp2=403
    aresp={:tag => "status", :attributes => { :code => "change_project_no_permission" } }
    match=nil
    prepare_request_with_user "tom", "thunder"
    do_change_project_meta_test(prj, resp1, resp2, aresp, match)
    # same with set_flag command ?
    post "/source/SourceprotectedProject?cmd=set_flag&flag=sourceaccess&status=enable"
    assert_response 403
    assert_match(/no permission to execute command/, @response.body)
    # admin
    resp1=:success
    resp2=:success
    aresp={:tag => "status", :attributes => { :code => "ok" } }
    match=true
    prepare_request_with_user "king", "sunflower"
    do_change_project_meta_test(prj, resp1, resp2, aresp, match)
    # maintainer
    prepare_request_with_user "sourceaccess_homer", "homer"
    do_change_project_meta_test(prj, resp1, resp2, aresp, match)
  end

  def do_change_project_meta_test (project, response1, response2, tag2, doesmatch)
   # Get meta file  
    get url_for(:controller => :source, :action => :project_meta, :project => project)
    assert_response response1
    if !( response2 && tag2 )
      #dummy write to check blocking
      put url_for(:action => :project_meta, :project => project), "<project name=\"#{project}\"><title></title><description></description></project>"
      assert_response 403 #4
#      assert_match(/unknown_project/, @response.body)
      assert_match(/create_project_no_permission/, @response.body)
      return
    end

    # Change description
    xml = @response.body
    new_desc = "Changed description"
    doc = REXML::Document.new( xml )
    d = doc.elements["//description"]
    d.text = new_desc

    # Write changed data back
    put url_for(:action => :project_meta, :project => project), doc.to_s
    assert_response response2
    assert_tag(tag2)

    # Get data again and check that it is the changed data
    get url_for(:action => :project_meta, :project => project)
    doc = REXML::Document.new( @response.body )
    d = doc.elements["//description"]
    assert_equal new_desc, d.text if doesmatch
  end
  private :do_change_project_meta_test


  def test_create_and_delete_project
    prepare_request_with_user("king", "sunflower")
    # Get meta file  
    get url_for(:controller => :source, :action => :project_meta, :project => "kde4")
    assert_response :success

    xml = @response.body
    doc = REXML::Document.new( xml )
    # change name to kde5: 
    d = doc.elements["/project"]
    d.delete_attribute( 'name' )   
    d.add_attribute( 'name', 'kde5' ) 
    put url_for(:controller => :source, :action => :project_meta, :project => "kde5"), doc.to_s
    assert_response(:success, message="--> king was not allowed to create a project")
    assert_tag( :tag => "status", :attributes => { :code => "ok" })

    # Get data again and check that the maintainer was added
    get url_for(:controller => :source, :action => :project_meta, :project => "kde5")
    assert_response :success
    assert_select "project[name=kde5]"
    assert_select "person[userid=king][role=maintainer]", {}, "Creator was not added as project maintainer"

    prepare_request_with_user "maintenance_coord", "power"
    delete "/source/kde5"
    assert_response 403
    prepare_request_with_user "fred", "geröllheimer"
    delete "/source/kde5"
    assert_response :success
  end
  
  
  def test_put_invalid_project_meta
    prepare_request_with_user "fred", "geröllheimer"

   # Get meta file  
    get url_for(:controller => :source, :action => :project_meta, :project => "kde4")
    assert_response :success

    xml = @response.body
    olddoc = REXML::Document.new( xml )
    doc = REXML::Document.new( xml )
    # Write corrupt data back
    put url_for(:controller => :source, :action => :project_meta, :project => "kde4"), doc.to_s + "</xml>"
    assert_response 400
    assert_tag :tag => "status", :attributes => { :code => "validation_failed" }

    prepare_request_with_user "king", "sunflower"
    # write to illegal location: 
    put url_for(:controller => :source, :action => :project_meta)
    assert_response 400
    assert_tag :tag => "status", :attributes => { :code => "validation_failed" }
    put url_for(:controller => :source, :action => :project_meta, :project => "."), doc.to_s
    assert_response 400
    assert_tag :tag => "status", :attributes => { :code => "invalid_project_name" }
    
    #must not create a project with different pathname and name in _meta.xml:
    put url_for(:controller => :source, :action => :project_meta, :project => "kde5"), doc.to_s
    assert_response 400
    assert_tag :tag => "status", :attributes => { :code => "project_name_mismatch" }
    #TODO: referenced repository names must exist
    
    
    #verify data is unchanged: 
    get url_for(:controller => :source, :action => :project_meta, :project => "kde4" )
    assert_response :success
    assert_equal( olddoc.to_s, REXML::Document.new( ( @response.body )).to_s)
  end
  
  
  def test_lock_project
    prepare_request_with_user "Iggy", "asdfasdf"
    put "/source/home:Iggy/TestLinkPack/_meta", "<package project='home:Iggy' name='TestLinkPack'> <title/> <description/> </package>"
    assert_response :success
    put "/source/home:Iggy/TestLinkPack/_link", "<link package='TestPack' />"
    assert_response :success

    # lock project
    get "/source/home:Iggy/_meta"
    assert_response :success
    doc = REXML::Document.new( @response.body )
    doc.elements["/project"].add_element "lock"
    doc.elements["/project/lock"].add_element "enable"
    put "/source/home:Iggy/_meta", doc.to_s
    assert_response :success
    get "/source/home:Iggy/_meta"
    assert_response :success
    assert_tag :parent => { :tag => "project" }, :tag => "lock" 
    assert_tag :parent => { :tag => "lock" }, :tag => "enable" 

    # modifications are not allowed anymore
    delete "/source/home:Iggy"
    assert_response 403
    delete "/source/home:Iggy/TestLinkPack"
    assert_response 403
    doc.elements["/project/description"].text = "new text"
    put "/source/home:Iggy/_meta", doc.to_s
    assert_response 403
    put "/source/home:Iggy/TestLinkPack/_link", ""
    assert_response 403

    # make project read-writable again
    doc.elements["/project/lock"].delete_element "enable"
    doc.elements["/project/lock"].add_element "disable"
    put "/source/home:Iggy/_meta", doc.to_s
    assert_response :success

    # cleanup works now again
    delete "/source/home:Iggy/TestLinkPack"
    assert_response :success
  end
  
  def test_lock_package
    prepare_request_with_user "Iggy", "asdfasdf"
    put "/source/home:Iggy/TestLinkPack/_meta", "<package project='home:Iggy' name='TestLinkPack'> <title/> <description/> </package>"
    assert_response :success

    # lock package
    get "/source/home:Iggy/TestLinkPack/_meta"
    assert_response :success
    doc = REXML::Document.new( @response.body )
    doc.elements["/package"].add_element "lock"
    doc.elements["/package/lock"].add_element "enable"
    put "/source/home:Iggy/TestLinkPack/_meta", doc.to_s
    assert_response :success
    get "/source/home:Iggy/TestLinkPack/_meta"
    assert_response :success
    assert_tag :parent => { :tag => "package" }, :tag => "lock" 
    assert_tag :parent => { :tag => "lock" }, :tag => "enable" 

    # modifications are not allowed anymore
    delete "/source/home:Iggy/TestLinkPack"
    assert_response 403
    doc.elements["/package/description"].text = "new text"
    put "/source/home:Iggy/TestLinkPack/_meta", doc.to_s
    assert_response 403
    put "/source/home:Iggy/TestLinkPack/_link", ""
    assert_response 403

    # make package read-writable again
    doc.elements["/package/lock"].delete_element "enable"
    doc.elements["/package/lock"].add_element "disable"
    put "/source/home:Iggy/TestLinkPack/_meta", doc.to_s
    assert_response :success

    # cleanup works now again
    delete "/source/home:Iggy/TestLinkPack"
    assert_response :success
  end
  
  def test_put_package_meta_with_invalid_permissions
    prepare_request_with_user "tom", "thunder"
    # The user is valid, but has weak permissions
    
    get url_for(:controller => :source, :action => :package_meta, :project => "kde4", :package => "kdelibs")
    assert_response :success

    # Change description
    xml = @response.body
    new_desc = "Changed description"
    olddoc = REXML::Document.new( xml )
    doc = REXML::Document.new( xml )
    d = doc.elements["//description"]
    d.text = new_desc

    # Write changed data back
    put url_for(:controller => :source, :action => :package_meta, :project => "kde4", :package => "kdelibs"), doc.to_s
    assert_response 403
    
    #verify data is unchanged: 
    get url_for(:controller => :source, :action => :package_meta, :project => "kde4", :package => "kdelibs")
    assert_response :success
    assert_equal( olddoc.to_s, REXML::Document.new(( @response.body )).to_s)    
  end

  def test_put_package_meta_to_hidden_pkg_invalid_permissions
    prepare_request_with_user "tom", "thunder"
    # The user is valid, but has weak permissions
    get url_for(:controller => :source, :action => :package_meta, :project => "HiddenProject", :package => "pack")
    assert_response 404

    # Write changed data back
    put url_for(:controller => :source, :action => :package_meta, :project => "HiddenProject", :package => "pack"), "<package name=\"pack\"><title></title><description></description></package>"
    assert_response 404
  end

  def do_change_package_meta_test (project, package, response1, response2, tag2, match)
   # Get meta file  
    get url_for(:controller => :source, :action => :package_meta, :project => project, :package => package)
    assert_response response1

    if !( response2 && tag2 )
      #dummy write to check blocking
      put url_for(:controller => :source, :action => :package_meta, :project => project, package => package), "<package name=\"#{package}\"><title></title><description></description></package>"
      assert_response 404
#      assert_match(/unknown_package/, @response.body)
      assert_match(/unknown_project/, @response.body)
      return
    end
    # Change description
    xml = @response.body
    new_desc = "Changed description"
    doc = REXML::Document.new( xml )
    d = doc.elements["//description"]
    d.text = new_desc

    # Write changed data back
    put url_for(:controller => :source, :action => :package_meta, :project => project, :package => package), doc.to_s
    assert_response response2 #(:success, "--> Was not able to update kdelibs _meta")   
    assert_tag tag2 #( :tag => "status", :attributes => { :code => "ok"} )

    # Get data again and check that it is the changed data
    get url_for(:controller => :source, :action => :package_meta, :project => project, :package => package)
    newdoc = REXML::Document.new( @response.body )
    d = newdoc.elements["//description"]
    #ignore updated change
    newdoc.root.attributes['updated'] = doc.root.attributes['updated']
    assert_equal new_desc, d.text if match
    assert_equal doc.to_s, newdoc.to_s if match
  end
  private :do_change_package_meta_test


  # admins, project-maintainer and package maintainer can edit package data
  def test_put_package_meta
    prj="kde4"
    pkg="kdelibs"
    resp1=:success
    resp2=:success
    aresp={:tag => "status", :attributes => { :code => "ok"} }
    match=true
    # admin
    prepare_request_with_user "king", "sunflower"
    do_change_package_meta_test(prj,pkg,resp1,resp2,aresp,match)
    # maintainer via user
    prepare_request_with_user "fred", "geröllheimer"
    do_change_package_meta_test(prj,pkg,resp1,resp2,aresp,match)
    prepare_request_with_user "fredlibs", "geröllheimer"
    do_change_package_meta_test(prj,pkg,resp1,resp2,aresp,match)
    # maintainer via group
    prepare_request_with_user "adrian", "so_alone"
    do_change_package_meta_test(prj,pkg,resp1,resp2,aresp,match)

    # check history
    get "/source/kde4/kdelibs/_history?meta=1"
    assert_response :success
    assert_tag( :tag => "revisionlist" )
    assert_tag( :tag => "user", :content => "adrian" )
  end

  def test_put_package_meta_hidden_package
    prj="HiddenProject"
    pkg="pack"
    resp1=404
    resp2=nil
    aresp=nil
    match=false
    # uninvolved user
    prepare_request_with_user "fred", "geröllheimer"
    do_change_package_meta_test(prj,pkg,resp1,resp2,aresp,match)
    # admin
    resp1=:success
    resp2=:success
    aresp={:tag => "status", :attributes => { :code => "ok"} }
    match=true
    prepare_request_with_user "king", "sunflower"
    do_change_package_meta_test(prj,pkg,resp1,resp2,aresp,match)
    # maintainer
    prepare_request_with_user "hidden_homer", "homer"
    do_change_package_meta_test(prj,pkg,resp1,resp2,aresp,match)
  end

  def test_put_package_meta_sourceaccess_protected_package
    prj="SourceprotectedProject"
    pkg="pack"
    resp1=:success
    resp2=403
    aresp={:tag => "status", :attributes => { :code => "change_package_no_permission" } }
    match=nil
    # uninvolved user
    prepare_request_with_user "fred", "geröllheimer"
    do_change_package_meta_test(prj,pkg,resp1,resp2,aresp,match)
    # admin
    resp1=:success
    resp2=:success
    aresp={:tag => "status", :attributes => { :code => "ok"} }
    match=true
    prepare_request_with_user "king", "sunflower"
    do_change_package_meta_test(prj,pkg,resp1,resp2,aresp,match)
    # maintainer
    prepare_request_with_user "sourceaccess_homer", "homer"
    do_change_package_meta_test(prj,pkg,resp1,resp2,aresp,match)
  end

  def test_create_package_meta
    # user without any special roles
    prepare_request_with_user "fred", "geröllheimer"
    get url_for(:controller => :source, :action => :package_meta, :project => "kde4", :package => "kdelibs")
    assert_response :success
    #change name to kdelibs2
    xml = @response.body
    doc = REXML::Document.new( xml )
    d = doc.elements["/package"]
    d.delete_attribute( 'name' )   
    d.add_attribute( 'name', 'kdelibs2' ) 
    put url_for(:controller => :source, :action => :package_meta, :project => "kde4", :package => "kdelibs2"), doc.to_s
    assert_response :success
    assert_tag( :tag => "status", :attributes => { :code => "ok"} )
    # do not allow to create it with invalid name
    put url_for(:controller => :source, :action => :package_meta, :project => "kde4", :package => "kdelibs3"), doc.to_s
    assert_response 400
    
    # Get data again and check that the maintainer was added
    get url_for(:controller => :source, :action => :package_meta, :project => "kde4", :package => "kdelibs2")
    assert_response :success
    newdoc = REXML::Document.new( @response.body )
    d = newdoc.elements["/package"]
    assert_equal(d.attribute('name').value(), 'kdelibs2', message="Project name was not set to kdelibs2")

    # check for lacking permission to create a package
    prepare_request_with_user "tom", "thunder"
    d.delete_attribute( 'name' )   
    d.add_attribute( 'name', 'kdelibs3' ) 
    put url_for(:controller => :source, :action => :package_meta, :project => "kde4", :package => "kdelibs3"), newdoc.to_s
    assert_response 403
    assert_tag( :tag => "status", :attributes => { :code => "create_package_no_permission"} )
  end

  def test_captial_letter_change
    prepare_request_with_user "tom", "thunder"
    put "/source/home:tom:projectA/_meta", "<project name='home:tom:projectA'> <title/> <description/> <repository name='repoA'/> </project>"
    assert_response :success
    put "/source/home:tom:projectB/_meta", "<project name='home:tom:projectB'> <title/> <description/> <repository name='repoB'> <path project='home:tom:projectA' repository='repoA' /> </repository> </project>"
    assert_response :success
    get "/source/home:tom:projectB/_meta"
    assert_response :success
    assert_tag :tag => "path", :attributes => { :project => 'home:tom:projectA' }
    assert_no_tag :tag => "path", :attributes => { :project => 'home:tom:projecta' }

    # write again with a capital letter change
    put "/source/home:tom:projectB/_meta", "<project name='home:tom:projectB'> <title/> <description/> <repository name='repoB'> <path project='home:tom:projecta' repository='repoA' /> </repository> </project>"
    assert_response 404
    assert_tag :tag => "status", :attributes => { :code => 'unknown_project' }
    get "/source/home:tom:projectB/_meta"
    assert_response :success
    assert_tag :tag => "path", :attributes => { :project => 'home:tom:projectA' }
    assert_no_tag :tag => "path", :attributes => { :project => 'home:tom:projecta' }

    # change back using remote project
    put "/source/home:tom:projectB/_meta", "<project name='home:tom:projectB'> <title/> <description/> <repository name='repoB'> <path project='RemoteInstance:home:tom:projectA' repository='repoA' /> </repository> </project>"
    assert_response :success
    get "/source/home:tom:projectB/_meta"
    assert_response :success
    assert_tag :tag => "path", :attributes => { :project => 'RemoteInstance:home:tom:projectA' }
    assert_no_tag :tag => "path", :attributes => { :project => 'RemoteInstance:home:tom:projecta' }

if $ENABLE_BROKEN_TEST
# FIXME: the case insensitive database select is not okay.
    # and switch letter again
    put "/source/home:tom:projectB/_meta", "<project name='home:tom:projectB'> <title/> <description/> <repository name='repoB'> <path project='RemoteInstance:home:tom:projecta' repository='repoA' /> </repository> </project>"
    assert_response 404
    assert_tag :tag => "status", :attributes => { :code => 'unknown_project' }
    get "/source/home:tom:projectB/_meta"
    assert_response :success
    assert_tag :tag => "path", :attributes => { :project => 'RemoteInstance:home:tom:projectA' }
    assert_no_tag :tag => "path", :attributes => { :project => 'RemoteInstance:home:tom:projecta' }
end

    # cleanup
    delete "/source/home:tom:projectB"
    assert_response :success
    delete "/source/home:tom:projectA"
    assert_response :success
  end

  def test_repository_dependencies
    prepare_request_with_user "tom", "thunder"
    put "/source/home:tom:projectA/_meta", "<project name='home:tom:projectA'> <title/> <description/> <repository name='repoA'/> </project>"
    assert_response :success
    put "/source/home:tom:projectB/_meta", "<project name='home:tom:projectB'> <title/> <description/> <repository name='repoB'> <path project='home:tom:projectA' repository='repoA' /> </repository> </project>"
    assert_response :success
    # delete a repo
    put "/source/home:tom:projectA/_meta", "<project name='home:tom:projectA'> <title/> <description/> </project>"
    assert_response 400
    assert_tag( :tag => "status", :attributes => { :code => "repo_dependency"} )
    delete "/source/home:tom:projectA"
    assert_response 403
    put "/source/home:tom:projectA/_meta?force=1", "<project name='home:tom:projectA'> <title/> <description/> </project>"
    assert_response :success
    get "/source/home:tom:projectB/_meta"
    assert_response :success
    assert_tag :tag => 'path', :attributes => { :project => "deleted", :repository => "gone" }
    put "/source/home:tom:projectB/_meta", "<project name='home:tom:projectB'> <title/> <description/> </project>"
    assert_response :success

    # cleanup
    delete "/source/home:tom:projectA"
    assert_response :success
    delete "/source/home:tom:projectB"
    assert_response :success
  end

  def test_delete_project_with_repository_dependencies
    prepare_request_with_user "tom", "thunder"
    put "/source/home:tom:projectA/_meta", "<project name='home:tom:projectA'> <title/> <description/> <repository name='repoA'> <arch>i586</arch> </repository> </project>"
    assert_response :success
    put "/source/home:tom:projectB/_meta", "<project name='home:tom:projectB'> <title/> <description/> <repository name='repoB'> <path project='home:tom:projectA' repository='repoA' /> <arch>i586</arch> </repository> </project>"
    assert_response :success
    # delete the project including the repository
    delete "/source/home:tom:projectA"
    assert_response 403
    assert_tag( :tag => "status", :attributes => { :code => "repo_dependency"} )
    delete "/source/home:tom:projectA?force=1"
    assert_response :success
    get "/source/home:tom:projectB/_meta"
    assert_response :success
    assert_tag :tag => 'path', :attributes => { :project => "deleted", :repository => "gone" }
    put "/source/home:tom:projectB/_meta", "<project name='home:tom:projectB'> <title/> <description/> </project>"
    assert_response :success

    # cleanup
    delete "/source/home:tom:projectB"
    assert_response :success
  end

  def test_devel_project_cycle
    prepare_request_with_user "tom", "thunder"
    put "/source/home:tom:A/_meta", "<project name='home:tom:A'> <title/> <description/> </project>"
    assert_response :success
    put "/source/home:tom:B/_meta", "<project name='home:tom:B'> <title/> <description/> <devel project='home:tom:A'/> </project>"
    assert_response :success
    get "/source/home:tom:B/_meta"
    assert_response :success
    assert_tag :tag => 'devel', :attributes => { :project => 'home:tom:A' }
    put "/source/home:tom:C/_meta", "<project name='home:tom:C'> <title/> <description/> <devel project='home:tom:B'/> </project>"
    assert_response :success
    # no self reference
    put "/source/home:tom:A/_meta", "<project name='home:tom:A'> <title/> <description/> <devel project='home:tom:A'/> </project>"
    assert_response 400
    # create a cycle via new package
    put "/source/home:tom:A/_meta", "<project name='home:tom:A'> <title/> <description/> <devel project='home:tom:C'/> </project>"
    assert_response 400
    assert_tag( :tag => "status", :attributes => { :code => "project_cycle"} )
  end

  def test_devel_package_cycle
    prepare_request_with_user "tom", "thunder"
    put "/source/home:tom/packageA/_meta", "<package project='home:tom' name='packageA'> <title/> <description/> </package>"
    assert_response :success
    put "/source/home:tom/packageB/_meta", "<package project='home:tom' name='packageB'> <title/> <description/> <devel package='packageA' /> </package>"
    assert_response :success
    put "/source/home:tom/packageC/_meta", "<package project='home:tom' name='packageC'> <title/> <description/> <devel package='packageB' /> </package>"
    assert_response :success
    # no self reference
    put "/source/home:tom/packageA/_meta", "<package project='home:tom' name='packageA'> <title/> <description/> <devel package='packageA' /> </package>"
    assert_response 400
    # create a cycle via new package
    put "/source/home:tom/packageB/_meta", "<package project='home:tom' name='packageB'> <title/> <description/> <devel package='packageC' /> </package>"
    assert_response 400
    assert_tag( :tag => "status", :attributes => { :code => "devel_cycle"} )
    # create a cycle via existing package
    put "/source/home:tom/packageA/_meta", "<package project='home:tom' name='packageA'> <title/> <description/> <devel package='packageB' /> </package>"
    assert_response 400
    assert_tag( :tag => "status", :attributes => { :code => "devel_cycle"} )
  end

  def do_test_change_package_meta (project, package, response1, response2, tag2, response3, select3)
    get url_for(:controller => :source, :action => :package_meta, :project => project, :package => package)
    assert_response response1
    if !(response2 || tag2 || response3 || select3)
      #dummy write to check blocking
      put url_for(:controller => :source, :action => :package_meta, :project => project, package => package), "<package name=\"#{package}\"><title></title><description></description></package>"
      assert_response 404
#      assert_match(/unknown_package/, @response.body)
      assert_match(/unknown_project/, @response.body)
      return
    end
    xml = @response.body
    doc = REXML::Document.new( xml )
    d = doc.elements["/package"]
    b = d.add_element 'build'
    b.add_element 'enable'
    put url_for(:controller => :source, :action => :package_meta, :project => project, :package => package), doc.to_s
    assert_response response2
    assert_tag(tag2)

    get url_for(:controller => :source, :action => :package_meta, :project => project, :package => package)
    assert_response response3
    assert_select select3 if select3
  end

  def test_change_package_meta
    prj="kde4"      # project
    pkg="kdelibs"   # package
    resp1=:success  # assert response #1
    resp2=:success  # assert response #2
    atag2={ :tag => "status", :attributes => { :code => "ok"} } # assert_tag after response #2
    resp3=:success  # assert respons #3
    asel3="package > build > enable" # assert_select after response #3
    # user without any special roles
    prepare_request_with_user "fred", "geröllheimer"
    do_test_change_package_meta(prj,pkg,resp1,resp2,atag2,resp3,asel3)
  end

  def test_change_package_meta_hidden
    prj="HiddenProject"
    pkg="pack"
    # uninvolved user
    resp1=404
    resp2=nil
    atag2=nil
    resp3=nil
    asel3=nil
    prepare_request_with_user "fred", "geröllheimer"
    do_test_change_package_meta(prj,pkg,resp1,resp2,atag2,resp3,asel3)
    resp1=:success
    resp2=:success
    atag2={ :tag => "status", :attributes => { :code => "ok"} }
    resp3=:success
    asel3="package > build > enable"
    # maintainer
    prepare_request_with_user "adrian", "so_alone"
    do_test_change_package_meta(prj,pkg,resp1,resp2,atag2,resp3,asel3)
  end

  def test_change_package_meta_sourceaccess_protect
    prj="SourceprotectedProject"
    pkg="pack"
    # uninvolved user
    resp1=:success
    resp2=403
    atag2={ :tag => "status", :attributes => { :code => "change_package_no_permission"} }
    resp3=:success
    asel3=nil
    prepare_request_with_user "fred", "geröllheimer"
    do_test_change_package_meta(prj,pkg,resp1,resp2,atag2,resp3,asel3)

    # maintainer
    resp1=:success
    resp2=:success
    atag2={ :tag => "status", :attributes => { :code => "ok"} }
    resp3=:success
    asel3="package > build > enable"
    prepare_request_with_user "sourceaccess_homer", "homer"
    do_test_change_package_meta(prj,pkg,resp1,resp2,atag2,resp3,asel3)
  end

  def test_put_invalid_package_meta
    prepare_request_with_user "fredlibs", "geröllheimer"
   # Get meta file  
    get url_for(:controller => :source, :action => :package_meta, :project => "kde4", :package => "kdelibs")
    assert_response :success

    xml = @response.body
    olddoc = REXML::Document.new( xml )
    doc = REXML::Document.new( xml )
    # Write corrupt data back
    put url_for(:controller => :source, :action => :package_meta, :project => "kde4", :package => "kdelibs"), doc.to_s + "</xml>"
    assert_response 400

    prepare_request_with_user "king", "sunflower"
    # write to illegal location: 
    put url_for(:controller => :source, :action => :package_meta, :project => "kde4", :package => "."), doc.to_s
    assert_response 400
    assert_tag :tag => "status", :attributes => { :code => "invalid_package_name" }
    
    #must not create a package with different pathname and name in _meta.xml:
    put url_for(:controller => :source, :action => :package_meta, :project => "kde4", :package => "kdelibs2000"), doc.to_s
    assert_response 400
    assert_tag :tag => "status", :attributes => { :code => "package_name_mismatch" }
    #verify data is unchanged: 
    get url_for(:controller => :source, :action => :package_meta, :project => "kde4", :package => "kdelibs")
    assert_response :success
    assert_equal( olddoc.to_s, REXML::Document.new( ( @response.body )).to_s)
  end



  def test_read_file
    prepare_request_with_user "tom", "thunder"
    get "/source/kde4/kdelibs/my_patch.diff"
    assert_response :success
    assert_equal( @response.body.to_s, "argl" )
    
    get "/source/kde4/kdelibs/BLUB"
    #STDERR.puts(@response.body)
    assert_response 404
    assert_tag( :tag => "status" )
    
    get "/source/kde4/kdelibs/../kdebase/_meta"
    #STDERR.puts(@response.body)
    assert_response( 404, "Was able to read file outside of package scope" )
    assert_tag( :tag => "status" )
  end

  def test_read_file_hidden_proj
    # nobody 
    prepare_request_with_user "adrian_nobody", "so_alone"
    get "/source/HiddenProject/pack/my_file"

    assert_response 404
    assert_tag :tag => "status", :attributes => { :code => "unknown_project"} 
    # uninvolved, 
    prepare_request_with_user "tom", "thunder"
    get "/source/HiddenProject/pack/my_file"
    assert_response 404
    assert_tag :tag => "status", :attributes => { :code => "unknown_project"} 
    # reader
    # downloader
    # maintainer
    prepare_request_with_user "hidden_homer", "homer"
    get "/source/HiddenProject/pack/my_file"
    assert_response :success
    assert_equal( @response.body.to_s, "Protected Content")
    # admin
    prepare_request_with_user "king", "sunflower"
    get "/source/HiddenProject/pack/my_file"
    assert_response :success
    assert_equal( @response.body.to_s, "Protected Content")
  end

  def test_read_filelist_sourceaccess_proj
    # nobody 
    prepare_request_with_user "adrian_nobody", "so_alone"
    get "/source/SourceprotectedProject/pack"
    assert_response 403
    assert_tag :tag => "status", :attributes => { :code => "source_access_no_permission"} 
    # uninvolved, 
    prepare_request_with_user "tom", "thunder"
    get "/source/SourceprotectedProject/pack"
    assert_response 403
    assert_tag :tag => "status", :attributes => { :code => "source_access_no_permission"} 
    # reader
    # downloader
    # maintainer
    prepare_request_with_user "sourceaccess_homer", "homer"
    get "/source/SourceprotectedProject/pack"
    assert_response :success
    assert_tag :tag => "directory"
    # admin
    prepare_request_with_user "king", "sunflower"
    get "/source/SourceprotectedProject/pack"
    assert_response :success
    assert_tag :tag => "directory"
  end

  def test_read_file_sourceaccess_proj
    # nobody 
    prepare_request_with_user "adrian_nobody", "so_alone"
    get "/source/SourceprotectedProject/pack/my_file"
    assert_response 403
    assert_tag :tag => "status", :attributes => { :code => "source_access_no_permission"} 
    # uninvolved, 
    prepare_request_with_user "tom", "thunder"
    get "/source/SourceprotectedProject/pack/my_file"
    assert_response 403
    assert_tag :tag => "status", :attributes => { :code => "source_access_no_permission"} 
    # reader
    # downloader
    # maintainer
    prepare_request_with_user "sourceaccess_homer", "homer"
    get "/source/SourceprotectedProject/pack/my_file"
    assert_response :success
    assert_equal( @response.body.to_s, "Protected Content")
    # admin
    prepare_request_with_user "king", "sunflower"
    get "/source/SourceprotectedProject/pack/my_file"
    assert_response :success
    assert_equal( @response.body.to_s, "Protected Content")
  end

  def add_file_to_package (url1, asserttag1, url2, assertresp2, 
                               assertselect2, assertselect2rev, 
                               assertresp3, asserteq3, assertresp4)
    get url1
    # before md5
    assert_tag asserttag1 if asserttag1
    teststring = '&;'
    put url2, teststring
    assert_response assertresp2
    # afterwards new md5
    assert_select assertselect2, assertselect2rev if assertselect2
    # reread file
    get url2
    assert_response assertresp3 
    assert_equal teststring, @response.body if asserteq3
    # delete
    delete url2
    assert_response assertresp4
    # file gone
    get url2
    assert_response 404 if asserteq3
  end
  private :add_file_to_package

  def test_add_file_to_package_hidden
    # uninvolved user
    prepare_request_with_user "fredlibs", "geröllheimer"
    url1="/source/HiddenProject/pack"
    asserttag1={ :tag => 'status', :attributes => { :code => "unknown_project"} }
    url2="/source/HiddenProject/pack/testfile"
    assertresp2=404
    assertselect2=nil
    assertselect2rev=nil
    assertresp3=404
    asserteq3=nil
    assertresp4=404
    add_file_to_package(url1, asserttag1, url2, assertresp2, 
                               assertselect2, assertselect2rev, 
                               assertresp3, asserteq3, assertresp4)
    # nobody 
    prepare_request_with_user "adrian_nobody", "so_alone"
    add_file_to_package(url1, asserttag1, url2, assertresp2, 
                               assertselect2, assertselect2rev, 
                               assertresp3, asserteq3, assertresp4)
    # maintainer
    prepare_request_with_user "hidden_homer", "homer"
    asserttag1={:tag => 'directory', :attributes => { :srcmd5 => "47a5fb1c73c75bb252283e2ad1110182" }}
    assertresp2=:success
    assertselect2="revision > srcmd5"
    assertselect2rev='16bbde7f26e318a5c893c182f7a3d433'
    assertresp3=:success
    asserteq3=true
    assertresp4=:success
    add_file_to_package(url1, asserttag1, url2, assertresp2, 
                               assertselect2, assertselect2rev, 
                               assertresp3, asserteq3, assertresp4)
    # admin
    prepare_request_with_user "king", "sunflower"
    add_file_to_package(url1, asserttag1, url2, assertresp2, 
                               assertselect2, assertselect2rev, 
                               assertresp3, asserteq3, assertresp4)
  end

  def test_add_file_to_package_sourceaccess_protect
    # uninvolved user
    prepare_request_with_user "fredlibs", "geröllheimer"
    url1="/source/SourceprotectedProject/pack"
    url2="/source/SourceprotectedProject/pack/testfile"
    assertresp2=403
    assertselect2=nil
    assertselect2rev=nil
    assertresp3=403
    asserteq3=nil
    assertresp4=403
    add_file_to_package(url1, nil, url2, assertresp2, 
                               assertselect2, assertselect2rev, 
                               assertresp3, asserteq3, assertresp4)
    # nobody 
    prepare_request_with_user "adrian_nobody", "so_alone"
    add_file_to_package(url1, nil, url2, assertresp2, 
                               assertselect2, assertselect2rev, 
                               assertresp3, asserteq3, assertresp4)
    # maintainer
    prepare_request_with_user "sourceaccess_homer", "homer"
    asserttag1={:tag => 'directory', :attributes => { :srcmd5 => "47a5fb1c73c75bb252283e2ad1110182" }}
    assertresp2=:success
    assertselect2="revision > srcmd5"
    assertselect2rev='16bbde7f26e318a5c893c182f7a3d433'
    assertresp3=:success
    asserteq3=true
    assertresp4=:success
    add_file_to_package(url1, asserttag1, url2, assertresp2, 
                               assertselect2, assertselect2rev, 
                               assertresp3, asserteq3, assertresp4)
    # admin
    prepare_request_with_user "king", "sunflower"
    add_file_to_package(url1, asserttag1, url2, assertresp2, 
                               assertselect2, assertselect2rev, 
                               assertresp3, asserteq3, assertresp4)
  end

  def test_add_file_to_package
    url1="/source/kde4/kdelibs"
    asserttag1={ :tag => 'directory', :attributes => { :srcmd5 => "1636661d96a88cd985d82dc611ebd723" } }
    url2="/source/kde4/kdelibs/testfile"
    assertresp2=:success
    assertselect2="revision > srcmd5"
    assertselect2rev='bc1d31b2403fa8925b257101b96196ec'
    assertresp3=:success
    asserteq3=true
    assertresp4=:success
    prepare_request_with_user "fredlibs", "geröllheimer"
    add_file_to_package(url1, asserttag1, url2, assertresp2, 
                               assertselect2, assertselect2rev, 
                               assertresp3, asserteq3, assertresp4)
    prepare_request_with_user "fred", "geröllheimer"
    add_file_to_package(url1, asserttag1, url2, assertresp2, 
                               assertselect2, assertselect2rev, 
                               assertresp3, asserteq3, assertresp4)
    prepare_request_with_user "king", "sunflower"
    add_file_to_package(url1, asserttag1, url2, assertresp2, 
                               assertselect2, assertselect2rev, 
                               assertresp3, asserteq3, assertresp4)
    # write without permission: 
    prepare_request_with_user "tom", "thunder"
    get url_for(:controller => :source, :action => :file, :project => "kde4", :package => "kdelibs", :file => "my_patch.diff")
    assert_response :success
    origstring = @response.body.to_s
    teststring = "&;"
    put url_for(:action => :file, :project => "kde4", :package => "kdelibs", :file => "my_patch.diff"), teststring
    assert_response( 403, message="Was able to write a package file without permission" )
    assert_tag( :tag => "status" )
    
    # check that content is unchanged: 
    get url_for(:controller => :source, :action => :file, :project => "kde4", :package => "kdelibs", :file => "my_patch.diff")
    assert_response :success
    assert_equal( @response.body.to_s, origstring, message="Package file was changed without permissions" )

    # invalid permission
    ActionController::IntegrationTest::reset_auth 
    delete "/source/kde4/kdelibs/my_patch.diff"
    assert_response 401

    prepare_request_with_user "adrian_nobody", "so_alone"
    delete "/source/kde4/kdelibs/my_patch.diff"
    assert_response 403
  
    get "/source/kde4/kdelibs/my_patch.diff"
    assert_response :success
  end
  
  def test_get_project_meta_history
    ActionController::IntegrationTest::reset_auth 
    get "/source/kde4/_project/_history"
    assert_response 401
    prepare_request_with_user "fredlibs", "geröllheimer"
    get "/source/kde4/_project/_history"
    assert_response :success
    assert_tag( :tag => "revisionlist" )
    get "/source/kde4/_project/_history?meta=1"
    assert_response :success
    assert_tag( :tag => "revisionlist" )
  end

  def test_remove_and_undelete_operations
    ActionController::IntegrationTest::reset_auth 
    delete "/source/kde4/kdelibs"
    assert_response 401
    delete "/source/kde4"
    assert_response 401

    # delete single package in project
    prepare_request_with_user "fredlibs", "geröllheimer"
    put "/source/kde4/kdelibs/DUMMYFILE", "dummy"
    assert_response :success
    # to have different revision number in meta and plain files
    delete "/source/kde4/kdelibs?user=illegal&comment=test%20deleted" 
    assert_response :success

    get "/source/kde4/kdelibs" 
    assert_response 404
    get "/source/kde4/kdelibs/_meta" 
    assert_response 404

    # check history
    get "/source/kde4/kdelibs/_history?deleted=1" 
    assert_response :success
    assert_tag( :parent => { :tag => "revision" }, :tag => "user", :content => "fredlibs" )
    assert_tag( :parent => { :tag => "revision" }, :tag => "comment", :content => "test deleted" )
    get "/source/kde4/kdelibs/_history?meta=1&deleted=1" 
    assert_tag( :parent => { :tag => "revision" }, :tag => "user", :content => "fredlibs" )
    assert_tag( :parent => { :tag => "revision" }, :tag => "comment", :content => "test deleted" )
    assert_response :success

    # list deleted packages
    get "/source/kde4", :deleted => 1
    assert_response :success
    assert_tag( :tag => "entry", :attributes => { :name => "kdelibs"} )

    # access to files of a deleted package
    get "/source/kde4/kdelibs/_history", :deleted => 1
    assert_response :success
    node = ActiveXML::XMLNode.new(@response.body)
    srcmd5 = node.each_revision.last.srcmd5.text 
    #if $ENABLE_BROKEN_TEST
# FIXME: this is currently not working in backend
#    get "/source/kde4/kdelibs", :deleted => 1, :rev => srcmd5
#    assert_response :success
#    get "/source/kde4/kdelibs/my_patch.diff", :deleted => 1, :rev => 
#    assert_response :success

    # undelete single package
    post "/source/kde4/kdelibs", :cmd => :undelete
    assert_response :success
    get "/source/kde4/kdelibs"
    assert_response :success
    get "/source/kde4/kdelibs/_meta"
    assert_response :success

    # delete entire project
    delete "/source/kde4" 
    assert_response :success

    get "/source/kde4" 
    assert_response 404
    get "/source/kde4/_meta" 
    assert_response 404

    # list content of deleted project
    prepare_request_with_user "king", "sunflower"
    get "/source", :deleted => 1
    assert_response 200
    assert_tag( :tag => "entry", :attributes => { :name => "kde4"} )
    prepare_request_with_user "fredlibs", "geröllheimer"
    get "/source", :deleted => 1
    assert_response 403
    assert_match(/only admins can see deleted projects/, @response.body)

    prepare_request_with_user "fredlibs", "geröllheimer"
    # undelete project
    post "/source/kde4", :cmd => :undelete
    assert_response 403

    prepare_request_with_user "king", "sunflower"
    post "/source/kde4", :cmd => :undelete
    assert_response :success

    # content got restored ?
    get "/source/kde4"
    assert_response :success
    get "/source/kde4/_project"

    assert_response :success
    get "/source/kde4/_meta"
    assert_response :success
    get "/source/kde4/kdelibs"
    assert_response :success
    get "/source/kde4/kdelibs/_meta"
    assert_response :success
    get "/source/kde4/kdelibs/my_patch.diff"
    assert_response :success
    delete "/source/kde4/kdelibs/DUMMYFILE" # restore as before
    assert_response :success

    # undelete project again
    post "/source/kde4", :cmd => :undelete
    assert_response 404
    assert_match(/project 'kde4' already exists/, @response.body)
  end

  def test_remove_project_and_verify_repositories
    prepare_request_with_user "tom", "thunder" 
    delete "/source/home:coolo"
    assert_response 403
    assert_select "status[code] > summary", /Unable to delete project home:coolo; following repositories depend on this project:/

    delete "/source/home:coolo", :force => 1
    assert_response :success

    # verify the repo is updated
    get "/source/home:coolo:test/_meta"
    node = ActiveXML::XMLNode.new(@response.body)
    assert_equal node.repository.name, "home_coolo"
    assert_equal node.repository.path.project, "deleted"
    assert_equal node.repository.path.repository, "gone"
  end

  def test_diff_package
    prepare_request_with_user "tom", "thunder" 
    post "/source/home:Iggy/TestPack?oproject=kde4&opackage=kdelibs&cmd=diff"
    assert_response :success
  end

  def test_meta_diff_package
    prepare_request_with_user "tom", "thunder" 
    post "/source/home:Iggy/TestPack?oproject=kde4&opackage=kdelibs&cmd=diff&meta=1"
    assert_response :success
    assert_match(/<\/package>/, @response.body)

    post "/source/home:Iggy/_project?oproject=kde4&opackage=_project&cmd=diff&meta=1"
    assert_response :success
    assert_match(/<\/project>/, @response.body)
  end

  def test_diff_package_hidden_project
    prepare_request_with_user "tom", "thunder"
    post "/source/HiddenProject/pack?oproject=kde4&opackage=kdelibs&cmd=diff"
    assert_response 404
    assert_tag :tag => 'status', :attributes => { :code => "unknown_project"}
    #reverse
    post "/source/kde4/kdelibs?oproject=HiddenProject&opackage=pack&cmd=diff"
    assert_response 404
    assert_tag :tag => 'status', :attributes => { :code => "unknown_project"} # was package

    prepare_request_with_user "hidden_homer", "homer"
    post "/source/HiddenProject/pack?oproject=kde4&opackage=kdelibs&cmd=diff"
    assert_response :success
    assert_match(/Minimal rpm package for testing the build controller/, @response.body)
    # reverse
    post "/source/kde4/kdelibs?oproject=HiddenProject&opackage=pack&cmd=diff"
    assert_response :success
    assert_match(/argl/, @response.body)

    prepare_request_with_user "king", "sunflower"
    post "/source/HiddenProject/pack?oproject=kde4&opackage=kdelibs&cmd=diff"
    assert_response :success
    assert_match(/Minimal rpm package for testing the build controller/, @response.body)
    # reverse
    prepare_request_with_user "king", "sunflower"
    post "/source/kde4/kdelibs?oproject=HiddenProject&opackage=pack&cmd=diff"
    assert_response :success
    assert_match(/argl/, @response.body)
  end

  def test_diff_package_sourceaccess_protected_project
    prepare_request_with_user "tom", "thunder"
    post "/source/SourceprotectedProject/pack?oproject=kde4&opackage=kdelibs&cmd=diff"
    assert_response 403
    assert_tag :tag => 'status', :attributes => { :code => "source_access_no_permission"}
    #reverse
    post "/source/kde4/kdelibs?oproject=SourceprotectedProject&opackage=pack&cmd=diff"
    assert_response 403
    assert_tag :tag => 'status', :attributes => { :code => "source_access_no_permission"}

    prepare_request_with_user "sourceaccess_homer", "homer"
    post "/source/SourceprotectedProject/pack?oproject=kde4&opackage=kdelibs&cmd=diff"
    assert_response :success
    assert_match(/Protected Content/, @response.body)
    # reverse
    post "/source/kde4/kdelibs?oproject=SourceprotectedProject&opackage=pack&cmd=diff"
    assert_response :success
    assert_match(/argl/, @response.body)

    prepare_request_with_user "king", "sunflower"
    post "/source/SourceprotectedProject/pack?oproject=kde4&opackage=kdelibs&cmd=diff"
    assert_response :success
    assert_match(/Protected Content/, @response.body)
    # reverse
    prepare_request_with_user "king", "sunflower"
    post "/source/kde4/kdelibs?oproject=SourceprotectedProject&opackage=pack&cmd=diff"
    assert_response :success
    assert_match(/argl/, @response.body)
  end


  def test_pattern
    ActionController::IntegrationTest::reset_auth 
    put "/source/kde4/_pattern/mypattern", load_backend_file("pattern/digiKam.xml")
    assert_response 401

    prepare_request_with_user "adrian_nobody", "so_alone"
    get "/source/DoesNotExist/_pattern"
    assert_response 404
    get "/source/kde4/_pattern"
    assert_response :success
    get "/source/kde4/_pattern/DoesNotExist"
    assert_response 404
    put "/source/kde4/_pattern/mypattern", load_backend_file("pattern/digiKam.xml")
    assert_response 403
    assert_match(/put_file_no_permission/, @response.body)

    prepare_request_with_user "tom", "thunder"
    get "/source/home:coolo:test"
    assert_response :success
    assert_no_match(/_pattern/, @response.body)
    put "/source/home:coolo:test/_pattern/mypattern", "broken"
    assert_response 400
    assert_match(/validation error/, @response.body)
    put "/source/home:coolo:test/_pattern/mypattern", load_backend_file("pattern/digiKam.xml")
    assert_response :success
    get "/source/home:coolo:test/_pattern/mypattern"
    assert_response :success
    get "/source/home:coolo:test"
    assert_response :success
    assert_match(/_pattern/, @response.body)

    # delete failure
    prepare_request_with_user "adrian_nobody", "so_alone"
    delete "/source/home:coolo:test/_pattern/mypattern"
    assert_response 403

    # successfull delete
    prepare_request_with_user "tom", "thunder"
    delete "/source/home:coolo:test/_pattern/mypattern"
    assert_response :success
    delete "/source/home:coolo:test/_pattern/mypattern"
    assert_response 404
    delete "/source/home:coolo:test/_pattern"
    assert_response :success
    delete "/source/home:coolo:test/_pattern"
    assert_response 404
  end

  def test_prjconf
    ActionController::IntegrationTest::reset_auth 
    get url_for(:controller => :source, :action => :project_config, :project => "DoesNotExist")
    assert_response 401
    prepare_request_with_user "adrian_nobody", "so_alone"
    get url_for(:controller => :source, :action => :project_config, :project => "DoesNotExist")
    assert_response 404
    get url_for(:controller => :source, :action => :project_config, :project => "kde4")
    assert_response :success

    prepare_request_with_user "adrian_nobody", "so_alone"
    put url_for(:controller => :source, :action => :project_config, :project => "kde4"), "Substitute: nix da"
    assert_response 403

    prepare_request_with_user "tom", "thunder"
    put url_for(:controller => :source, :action => :project_config, :project => "home:coolo:test"), "Substitute: nix da"
    assert_response :success
    get url_for(:controller => :source, :action => :project_config, :project => "home:coolo:test")
    assert_response :success
  end

  def test_pubkey
    ActionController::IntegrationTest::reset_auth 
    prepare_request_with_user "tom", "thunder"
    get url_for(:controller => :source, :action => :project_pubkey, :project => "DoesNotExist")
    assert_response 404
    get url_for(:controller => :source, :action => :project_pubkey, :project => "kde4")
    assert_response 404
    assert_match(/kde4: no pubkey available/, @response.body)
    get url_for(:controller => :source, :action => :project_pubkey, :project => "BaseDistro")
    assert_response :success

    delete url_for(:controller => :source, :action => :project_pubkey, :project => "kde4")
    assert_response 403

    # FIXME: make a successful deletion of a key
  end

  def test_linked_project_operations
    # first go with a read-only user
    prepare_request_with_user "tom", "thunder"
    # pack2 exists only via linked project
    get "/source/BaseDistro2:LinkedUpdateProject/pack2"
    assert_response :success
    delete "/source/BaseDistro2:LinkedUpdateProject/pack2"
    assert_response 404
    assert_match(/unknown_package/, @response.body)

    # test not permitted commands
    post "/build/BaseDistro2:LinkedUpdateProject", :cmd => "rebuild"
    assert_response 403
    post "/build/BaseDistro2:LinkedUpdateProject", :cmd => "wipe"
    assert_response 403
    assert_match(/permission to execute command on project BaseDistro2:LinkedUpdateProject/, @response.body)
    post "/source/BaseDistro2:LinkedUpdateProject/pack2", :cmd => "deleteuploadrev"
    assert_response 404
    assert_match(/unknown_package/, @response.body)
    post "/source/BaseDistro2:LinkedUpdateProject/pack2", :cmd => "commitfilelist"
    assert_response 404
    assert_match(/unknown_package/, @response.body)
    post "/source/BaseDistro2:LinkedUpdateProject/pack2", :cmd => "commit"
    assert_response 404
    assert_match(/unknown_package/, @response.body)
    post "/source/BaseDistro2:LinkedUpdateProject/pack2", :cmd => "linktobranch"
    assert_response 404
    assert_match(/unknown_package/, @response.body)

    # test permitted commands
    post "/source/BaseDistro2:LinkedUpdateProject/pack2", :cmd => "diff", :oproject => "RemoteInstance:BaseDistro", :opackage => "pack1"
    assert_response :success
    post "/source/BaseDistro2:LinkedUpdateProject/pack2", :cmd => "branch"
    assert_response :success
# FIXME: construct a linked package object to test this
#    post "/source/BaseDistro2:LinkedUpdateProject/pack2", :cmd => "linkdiff"
#    assert_response :success

    # read-write user, binary operations must be allowed
    prepare_request_with_user "king", "sunflower"
    # obsolete with OBS 3.0, rebuild only via /build/
    post "/source/BaseDistro2:LinkedUpdateProject/pack2", :cmd => "rebuild"
    assert_response :success
    post "/build/BaseDistro2:LinkedUpdateProject", :cmd => "rebuild", :package => "pack2"
    assert_response :success
    post "/build/BaseDistro2:LinkedUpdateProject", :cmd => "wipe"
    assert_response :success

    # create package and remove it again
    get "/source/BaseDistro2:LinkedUpdateProject/pack2"
    assert_response :success
    delete "/source/BaseDistro2:LinkedUpdateProject/pack2"
    assert_response 404
    post "/source/BaseDistro2:LinkedUpdateProject/pack2", :cmd => "copy", :oproject => "BaseDistro:Update", :opackage => "pack2"
    assert_response :success
    post "/source/BaseDistro2:LinkedUpdateProject/pack2", :cmd => "undelete"
    assert_response 404
    assert_match(/package_exists/, @response.body)
    delete "/source/BaseDistro2:LinkedUpdateProject/pack2"
    assert_response :success
    post "/source/BaseDistro2:LinkedUpdateProject/pack2", :cmd => "undelete"
    assert_response :success
  end

  def test_linktobranch
    prepare_request_with_user "Iggy", "asdfasdf"
    put "/source/home:Iggy/TestLinkPack/_meta", "<package project='home:Iggy' name='TestLinkPack'> <title/> <description/> </package>"
    assert_response :success
    put "/source/home:Iggy/TestLinkPack/_link", "<link package='TestPack' />"
    assert_response :success

    prepare_request_with_user "fred", "geröllheimer"
    post "/source/home:Iggy/TestLinkPack?cmd=linktobranch"
    assert_response 403

    prepare_request_with_user "Iggy", "asdfasdf"
    post "/source/home:Iggy/TestLinkPack?cmd=linktobranch"
    assert_response :success
    get "/source/home:Iggy/TestLinkPack/_link"
    assert_response :success
    assert_tag( :tag => "link", :attributes => { :package => "TestPack" } )
    assert_tag( :parent => { :tag => "patches", :content => nil }, :tag => "branch", :content => nil )

    delete "/source/home:Iggy/TestLinkPack"
    assert_response :success
  end

  def test_copy_package
    # fred has maintainer permissions in this single package of Iggys home
    # this is the osc way
    prepare_request_with_user "fred", "geröllheimer"
    put "/source/home:Iggy/TestPack/filename", 'CONTENT'
    assert_response :success
    get "/source/home:Iggy/TestPack/_history"
    assert_response :success
    node = ActiveXML::XMLNode.new(@response.body)
    revision = node.each_revision.last.value :rev

    # standard copy
    post "/source/home:fred/DELETE", :cmd => :copy, :oproject => "home:Iggy", :opackage => "TestPack"
    assert_response :success
    get "/source/home:fred/DELETE/_history"
    assert_response :success
    assert_tag :tag => "revisionlist", :children => { :count => 1 }

# FIXME: this is not yet supported in backend
if $ENABLE_BROKEN_TEST
    # copy with history
    post "/source/home:fred/DELETE", :cmd => :copy, :oproject => "home:Iggy", :opackage => "TestPack", :withhistory => "1"
    assert_response :success
    get "/source/home:fred/DELETE/_history"
    assert_response :success
    assert_tag :tag => "revisionlist", :children => { :count => revision }
end

    # cleanup
    delete "/source/home:fred/DELETE"
    assert_response :success
    delete "/source/home:Iggy/TestPack/filename"
    assert_response :success
  end

  def test_source_commits
    prepare_request_with_user "tom", "thunder"
    post "/source/home:Iggy/TestPack", :cmd => "commitfilelist"
    assert_response 403
    put "/source/home:Iggy/TestPack/filename", 'CONTENT'
    assert_response 403

    # fred has maintainer permissions in this single package of Iggys home
    # this is the osc way
    prepare_request_with_user "fred", "geröllheimer"
    delete "/source/home:Iggy/TestPack/filename" # in case other tests created it
    put "/source/home:Iggy/TestPack/filename?rev=repository", 'CONTENT'
    assert_response :success
    get "/source/home:Iggy/TestPack/filename"
    assert_response 404
    get "/source/home:Iggy/TestPack/_history?limit=1"
    assert_response :success
    assert_tag :tag => "revisionlist", :children => { :count => 1 }
    get "/source/home:Iggy/TestPack/_history"
    assert_response :success
    assert_no_tag :tag => "revisionlist", :children => { :count => 1 }
    node = ActiveXML::XMLNode.new(@response.body)
    revision = node.each_revision.last.value :rev
    revision = revision.to_i + 1
    post "/source/home:Iggy/TestPack?cmd=commitfilelist", ' <directory> <entry name="filename" md5="45685e95985e20822fb2538a522a5ccf" /> </directory> '
    assert_response :success
    get "/source/home:Iggy/TestPack/filename"
    assert_response :success
    get "/source/home:Iggy/TestPack/_history"
    assert_response :success
    assert_tag( :parent => { :tag => "revision", :attributes => { :rev => revision.to_s}, :content => nil }, :tag => "user", :content => "fred" )
    assert_tag( :parent => { :tag => "revision", :attributes => { :rev => revision.to_s}, :content => nil }, :tag => "srcmd5" )

    # delete file with commit
    delete "/source/home:Iggy/TestPack/filename"
    assert_response :success
    revision = revision.to_i + 1
    get "/source/home:Iggy/TestPack/filename"
    assert_response 404

    # this is the future webui way
    prepare_request_with_user "fred", "geröllheimer"
    put "/source/home:Iggy/TestPack/filename?rev=upload", 'CONTENT'
    assert_response :success
    get "/source/home:Iggy/TestPack/filename"
    assert_response :success
    get "/source/home:Iggy/TestPack/filename?rev=latest"
    assert_response 404
    get "/source/home:Iggy/TestPack/_history"
    assert_response :success
    revision = revision.to_i + 1
    assert_no_tag( :tag => "revision", :attributes => { :rev => revision.to_s} )
    post "/source/home:Iggy/TestPack?cmd=commit"
    assert_response :success
    get "/source/home:Iggy/TestPack/filename?rev=latest"
    assert_response :success
    get "/source/home:Iggy/TestPack/_history"
    assert_response :success
    assert_tag( :parent => { :tag => "revision", :attributes => { :rev => revision.to_s}, :content => nil }, :tag => "user", :content => "fred" )
    assert_tag( :parent => { :tag => "revision", :attributes => { :rev => revision.to_s}, :content => nil }, :tag => "srcmd5" )


    # test deleteuploadrev
    put "/source/home:Iggy/TestPack/anotherfilename?rev=upload", 'CONTENT'
    assert_response :success
    get "/source/home:Iggy/TestPack/anotherfilename"
    assert_response :success
    get "/source/home:Iggy/TestPack/anotherfilename?rev=latest"
    assert_response 404
    post "/source/home:Iggy/TestPack?cmd=deleteuploadrev"
    assert_response :success
    get "/source/home:Iggy/TestPack/anotherfilename"
    assert_response 404

    #
    # Test commits to special packages
    #
    prepare_request_with_user "Iggy", "asdfasdf"
    # _product must be created
    put "/source/home:Iggy/_product/_meta", "<package project='home:Iggy' name='_product'> <title/> <description/> </package>"
    assert_response :success
    put "/source/home:Iggy/_product/filename?rev=repository", 'CONTENT'
    assert_response :success
    post "/source/home:Iggy/_product?cmd=commitfilelist", ' <directory> <entry name="filename" md5="45685e95985e20822fb2538a522a5ccf" /> </directory> '
    assert_response :success
    get "/source/home:Iggy/_product/filename"
    assert_response :success
    put "/source/home:Iggy/_product/filename2", 'CONTENT'
    assert_response :success
    get "/source/home:Iggy/_product/filename2"
    assert_response :success

    # _pattern exists always
    put "/source/home:Iggy/_pattern/filename", 'CONTENT'
    assert_response 400 # illegal content
    put "/source/home:Iggy/_pattern/filename?rev=repository", load_backend_file("pattern/digiKam.xml")
    assert_response :success
    post "/source/home:Iggy/_pattern?cmd=commitfilelist", ' <directory> <entry name="filename" md5="d23e402af68579c3b30ff00f8c8424e0" /> </directory> '
    assert_response :success
    get "/source/home:Iggy/_pattern/filename"
    assert_response :success
    put "/source/home:Iggy/_pattern/filename2", load_backend_file("pattern/digiKam.xml")
    assert_response :success
    get "/source/home:Iggy/_pattern/filename2"
    assert_response :success

    # _project exists always
    put "/source/home:Iggy/_project/filename?rev=repository", 'CONTENT'
    assert_response :success
    post "/source/home:Iggy/_project?cmd=commitfilelist", ' <directory> <entry name="filename" md5="45685e95985e20822fb2538a522a5ccf" /> </directory> '
    assert_response :success
    get "/source/home:Iggy/_project/filename"
    assert_response :success
    put "/source/home:Iggy/_project/filename2", 'CONTENT'
    assert_response :success
    get "/source/home:Iggy/_project/filename2"
    assert_response :success
  end

  def test_list_of_linking_instances
    prepare_request_with_user "tom", "thunder"

    # list all linking projects
    post "/source/BaseDistro2", :cmd => "showlinked"
    assert_response :success
    assert_tag( :tag => "project", :attributes => { :name => "BaseDistro2:LinkedUpdateProject"}, :content => nil )

    # list all linking packages with a local link
    post "/source/BaseDistro/pack2", :cmd => "showlinked"
    assert_response :success
    assert_tag( :tag => "package", :attributes => { :project => "BaseDistro:Update", :name => "pack2" }, :content => nil )

    # list all linking packages, base package is a package on a remote OBS instance
# FIXME: support for this search is possible, but not yet implemented
#    post "/source/RemoteInstance:BaseDistro/pack", :cmd => "showlinked"
#    assert_response :success
#    assert_tag( :tag => "package", :attributes => { :project => "BaseDistro:Update", :name => "pack2" }, :content => nil )
  end

  def test_create_links
    prepare_request_with_user "king", "sunflower"
    put url_for(:controller => :source, :action => :project_meta, :project => "TEMPORARY"), 
        '<project name="TEMPORARY"> <title/> <description/> <person role="maintainer" userid="fred"/> </project>'
    assert_response 200
    # create packages via user without any special roles
    prepare_request_with_user "fred", "geröllheimer"
    get url_for(:controller => :source, :action => :package_meta, :project => "kde4", :package => "temporary")
    assert_response 404
    put url_for(:controller => :source, :action => :package_meta, :project => "kde4", :package => "temporary"), 
        '<package project="kde4" name="temporary"> <title/> <description/> </package>'
    assert_response 200
    assert_tag( :tag => "status", :attributes => { :code => "ok"} )
    put url_for(:controller => :source, :action => :package_meta, :project => "kde4", :package => "temporary2"), 
        '<package project="kde4" name="temporary2"> <title/> <description/> </package>'
    assert_response 200
    assert_tag( :tag => "status", :attributes => { :code => "ok"} )
    put "/source/kde4/temporary/file_in_linked_package", 'FILE CONTENT'
    assert_response 200
    put url_for(:controller => :source, :action => :package_meta, :project => "TEMPORARY", :package => "temporary2"), 
        '<package project="TEMPORARY" name="temporary2"> <title/> <description/> </package>'
    assert_response 200

    url = "/source/kde4/temporary/_link"
    url2 = "/source/kde4/temporary2/_link"
    url3 = "/source/TEMPORARY/temporary2/_link"

    # illegal targets
    put url, '<link project="notexisting" />'
    assert_response 404
    assert_tag :tag => "status", :attributes => { :code => "unknown_project" }
    put url, '<link project="kde4" package="notexiting" />'
    assert_response 404
    assert_tag :tag => "status", :attributes => { :code => "unknown_package" }

    # working local link
    put url, '<link project="BaseDistro" package="pack1" />'
    assert_response :success
    put url2, '<link package="temporary" />'
    assert_response :success
    put url3, '<link project="kde4" />'
    assert_response :success

    # working link to package via project link
    put url, '<link project="BaseDistro2:LinkedUpdateProject" package="pack2" />'
    assert_response :success
    # working link to remote package
    put url, '<link project="RemoteInstance:BaseDistro" package="pack1" />'
    assert_response :success
    put url, '<link project="RemoteInstance:BaseDistro2:LinkedUpdateProject" package="pack2" />'
    assert_response :success
    # working link to remote project link
    put url, '<link project="UseRemoteInstance" package="pack1" />'
    assert_response :success

    # check backend functionality
    get "/source/kde4/temporary"
    assert_response :success
    assert_no_tag( :tag => "entry", :attributes => {:name => "my_file"} )
    assert_tag( :tag => "entry", :attributes => {:name => "file_in_linked_package"} )
    assert_tag( :tag => "entry", :attributes => {:name => "_link"} )
    assert_tag( :tag => "linkinfo", :attributes => {:project => "UseRemoteInstance",  :package => "pack1",
                :srcmd5 => "96c3955b419fec1a637698e52b6a7d37", :xsrcmd5 => "6660e7c304ba16c50a415617bacb8b2f", :lsrcmd5 => "eabf686413b92c976ea073b11d797a2e"} )
    get "/source/kde4/temporary2?expand=1"
    assert_response :success
    assert_tag( :tag => "entry", :attributes => {:name => "my_file"} )
    assert_tag( :tag => "entry", :attributes => {:name => "file_in_linked_package"} )
    assert_tag( :tag => "linkinfo", :attributes => {:project => "kde4",  :package => "temporary"} )
    assert_no_tag( :tag => "entry", :attributes => {:name => "_link"} )
    get "/source/TEMPORARY/temporary2?expand=1"
    assert_response :success
    assert_tag( :tag => "entry", :attributes => {:name => "my_file"} )
    assert_tag( :tag => "entry", :attributes => {:name => "file_in_linked_package"} )
    assert_tag( :tag => "linkinfo", :attributes => {:project => "kde4",  :package => "temporary2"} )
    assert_no_tag( :tag => "entry", :attributes => {:name => "_link"} )

    # cleanup
    delete "/source/kde4/temporary"
    assert_response :success
    delete "/source/kde4/temporary2"
    assert_response :success
    prepare_request_with_user "king", "sunflower"
    delete "/source/TEMPORARY"
    assert_response :success
  end

  def test_create_project_with_repository_self_reference
    prepare_request_with_user "tom", "thunder"
    put url_for(:controller => :source, :action => :project_meta, :project => "home:tom:temporary"), 
        '<project name="home:tom:temporary"> <title/> <description/> 
           <repository name="me" />
         </project>'
    assert_response :success
    put url_for(:controller => :source, :action => :project_meta, :project => "home:tom:temporary"), 
        '<project name="home:tom:temporary"> <title/> <description/> 
           <repository name="me">
             <path project="home:tom:temporary" repository="me" />
           </repository>
         </project>'
    assert_response 400
    delete "/source/home:tom:temporary"
    assert_response :success
  end

  def test_use_project_link_as_non_maintainer
    prepare_request_with_user "tom", "thunder"
    put url_for(:controller => :source, :action => :project_meta, :project => "home:tom:temporary"), 
        '<project name="home:tom:temporary"> <title/> <description/> <link project="kde4" /> </project>'
    assert_response :success
    get "/source/home:tom:temporary"
    assert_response :success
    get "/source/home:tom:temporary/kdelibs"
    assert_response :success
    get "/source/home:tom:temporary/kdelibs/_history"
    assert_response :success
    delete "/source/home:tom:temporary/kdelibs"
    assert_response 404
    post "/source/home:tom:temporary/kdelibs", :cmd => :copy, :oproject => "home:tom:temporary", :opackage => "kdelibs"
    assert_response :success
    get "/source/home:tom:temporary/kdelibs/_meta"
    meta = @response.body
    assert_response :success
    delete "/source/home:tom:temporary/kdelibs"
    assert_response :success
    delete "/source/home:tom:temporary/kdelibs"
    assert_response 404

    # check if package creation is doing the right thing
    put "/source/home:tom:temporary/kdelibs/_meta", meta.dup
    assert_response :success
    delete "/source/home:tom:temporary/kdelibs"
    assert_response :success
    delete "/source/home:tom:temporary/kdelibs"
    assert_response 404

    # cleanup
    delete "/source/home:tom:temporary"
    assert_response :success
  end

  def test_delete_and_undelete_permissions
    ActionController::IntegrationTest::reset_auth 
    delete "/source/kde4/kdelibs"
    assert_response 401
    delete "/source/kde4"
    assert_response 401

    prepare_request_with_user "tom", "thunder"
    delete "/source/kde4/kdelibs"
    assert_response 403
    delete "/source/kde4"
    assert_response 403

    prepare_request_with_user "adrian", "so_alone"
    delete "/source/kde4/kdelibs"
    assert_response :success
    delete "/source/kde4"
    assert_response :success

    prepare_request_with_user "tom", "thunder"
    post "/source/kde4", :cmd => :undelete
    assert_response 403

    prepare_request_with_user "adrian", "so_alone"
    post "/source/kde4", :cmd => :undelete
    assert_response 403

    prepare_request_with_user "king", "sunflower"
    post "/source/kde4", :cmd => :undelete
    assert_response :success

    prepare_request_with_user "tom", "thunder"
    post "/source/kde4/kdelibs", :cmd => :undelete
    assert_response 403

    prepare_request_with_user "adrian", "so_alone"
    post "/source/kde4/kdelibs", :cmd => :undelete
    assert_response :success
  end

  def test_branch_package_delete_and_undelete
    ActionController::IntegrationTest::reset_auth 
    post "/source/home:Iggy/TestPack", :cmd => :branch, :target_project => "home:coolo:test"
    assert_response 401
    prepare_request_with_user "fredlibs", "geröllheimer"
    post "/source/home:Iggy/TestPack", :cmd => :branch, :target_project => "NotExisting"
    assert_response 403
    assert_match(/no permission to create project/, @response.body)
    post "/source/home:Iggy/TestPack", :cmd => :branch, :target_project => "home:coolo:test"
    assert_response 403
    assert_match(/no permission to/, @response.body)
    post "/source/home:Iggy/TestPack", :cmd => :branch, :target_project => "home:coolo:test", :force => "1" 
    assert_response 403
    assert_match(/no permission to/, @response.body)
 
    prepare_request_with_user "tom", "thunder"
    post "/source/home:Iggy/TestPack", :cmd => :branch, :target_project => "home:coolo:test"    
    assert_response :success
    get "/source/home:coolo:test/TestPack/_meta"
    assert_response :success

    # branch again
    post "/source/home:Iggy/TestPack", :cmd => :branch, :target_project => "home:coolo:test"    
    assert_response 400
    assert_match(/branch target package already exists/, @response.body)
    post "/source/home:Iggy/TestPack", :cmd => :branch, :target_project => "home:coolo:test", :force => "1"
    assert_response :success
    post "/source/home:Iggy/TestPack", :cmd => :branch, :target_project => "home:coolo:test", :force => "1", :rev => "1"
    assert_response :success
    post "/source/home:Iggy/TestPack", :cmd => :branch, :target_project => "home:coolo:test", :force => "1", :rev => "42424242"
    assert_response 400
    assert_match(/no such revision/, @response.body)
    # FIXME: do a real commit and branch afterwards

    # now with a new project
    post "/source/home:Iggy/TestPack", :cmd => :branch
    assert_response :success
    
    get "/source/home:tom:branches:home:Iggy/TestPack/_meta"
    assert_response :success

    get "/source/home:tom:branches:home:Iggy/_meta"
    ret = ActiveXML::XMLNode.new @response.body
    assert_equal ret.repository.name, "10.2"
    assert_equal ret.repository.path.repository, "10.2"
    assert_equal ret.repository.path.project, "home:Iggy"

    # check source link
    get "/source/home:tom:branches:home:Iggy/TestPack/_link"
    assert_response :success
    ret = ActiveXML::XMLNode.new @response.body
    assert_equal ret.project, "home:Iggy"
    assert_equal ret.package, "TestPack"
    assert_not_nil ret.baserev
    assert_not_nil ret.patches
    assert_not_nil ret.patches.branch

    # Branch a package with a defined devel package
    post "/source/kde4/kdelibs", :cmd => :branch
    assert_response :success
    assert_tag( :tag => "data", :attributes => { :name => "targetproject"}, :content => "home:tom:branches:home:coolo:test" )
    assert_tag( :tag => "data", :attributes => { :name => "targetpackage"}, :content => "kdelibs_DEVEL_package" )
    assert_tag( :tag => "data", :attributes => { :name => "sourceproject"}, :content => "home:coolo:test" )
    assert_tag( :tag => "data", :attributes => { :name => "sourcepackage"}, :content => "kdelibs_DEVEL_package" )

    # delete package
    ActionController::IntegrationTest::reset_auth 
    delete "/source/home:tom:branches:home:Iggy/TestPack"
    assert_response 401

    prepare_request_with_user "tom", "thunder"
    delete "/source/home:tom:branches:home:Iggy/TestPack"
    assert_response :success

    get "/source/home:tom:branches:home:Iggy/TestPack"
    assert_response 404
    get "/source/home:tom:branches:home:Iggy/TestPack/_meta"
    assert_response 404

    # undelete package
    post "/source/home:tom:branches:home:Iggy/TestPack", :cmd => :undelete
    assert_response :success

    # content got restored ?
    get "/source/home:tom:branches:home:Iggy/TestPack"
    assert_response :success
    get "/source/home:tom:branches:home:Iggy/TestPack/_meta"
    assert_response :success
    get "/source/home:tom:branches:home:Iggy/TestPack/_link"
    assert_response :success

    # undelete package again
    post "/source/home:tom:branches:home:Iggy/TestPack", :cmd => :undelete
    assert_response 404

  end

  def test_package_set_flag
    prepare_request_with_user "Iggy", "asdfasdf"

    get "/source/home:Iggy/TestPack/_meta"
    assert_response :success
    original = @response.body

    post "/source/home:unknown/Nothere?cmd=set_flag&repository=10.2&arch=i586&flag=build"
    assert_response 404
    assert_match(/unknown_project/, @response.body)

    post "/source/home:Iggy/Nothere?cmd=set_flag&repository=10.2&arch=i586&flag=build"
    assert_response 404
    assert_match(/unknown_package/, @response.body)

    post "/source/home:Iggy/Nothere?cmd=set_flag&repository=10.2&arch=i586&flag=build&status=enable"
    assert_response 404
    assert_match(/unknown_package/, @response.body)

    post "/source/home:Iggy/TestPack?cmd=set_flag&repository=10.2&arch=i586&flag=build&status=anything"
    assert_response 400
    assert_match(/Error: unknown status for flag 'anything'/, @response.body)

    post "/source/home:Iggy/TestPack?cmd=set_flag&repository=10.2&arch=i586&flag=shine&status=enable"
    assert_response 400
    assert_match(/Error: unknown flag type 'shine' not found./, @response.body)

    get "/source/home:Iggy/TestPack/_meta"
    assert_response :success
    # so far noting should have changed
    assert_equal original, @response.body

    post "/source/kde4/kdelibs?cmd=set_flag&repository=10.7&arch=i586&flag=build&status=enable"
    assert_response 403
    assert_match(/no permission to execute command/, @response.body)

    post "/source/home:Iggy/TestPack?cmd=set_flag&repository=10.7&arch=i586&flag=build&status=enable"
    assert_response :success # actually I consider forbidding repositories not existant

    get "/source/home:Iggy/TestPack/_meta"
    assert_not_equal original, @response.body

    get "/source/home:Iggy/TestPack/_meta?view=flagdetails"
    assert_response :success
  end


  def test_project_set_flag
    prepare_request_with_user "Iggy", "asdfasdf"

    get "/source/home:Iggy/_meta"
    assert_response :success
    original = @response.body

    post "/source/home:unknown?cmd=set_flag&repository=10.2&arch=i586&flag=build"
    assert_response 404

    post "/source/home:Iggy?cmd=set_flag&repository=10.2&arch=i586&flag=build"
    assert_response 400
    assert_match(/Required Parameter status missing/, @response.body)

    post "/source/home:Iggy?cmd=set_flag&repository=10.2&arch=i586&flag=build&status=anything"
    assert_response 400
    assert_match(/Error: unknown status for flag 'anything'/, @response.body)

    post "/source/home:Iggy?cmd=set_flag&repository=10.2&arch=i586&flag=shine&status=enable"
    assert_response 400
    assert_match(/Error: unknown flag type 'shine' not found./, @response.body)

    get "/source/home:Iggy/_meta"
    assert_response :success
    # so far noting should have changed
    assert_equal original, @response.body

    post "/source/kde4?cmd=set_flag&repository=10.7&arch=i586&flag=build&status=enable"
    assert_response 403
    assert_match(/no permission to execute command/, @response.body)

    post "/source/home:Iggy?cmd=set_flag&repository=10.7&arch=i586&flag=build&status=enable"
    assert_response :success # actually I consider forbidding repositories not existant

    get "/source/home:Iggy/_meta"
    assert_not_equal original, @response.body

    original = @response.body
    
    post "/source/home:Iggy?cmd=set_flag&flag=build&status=enable"
    assert_response :success # actually I consider forbidding repositories not existant

    get "/source/home:Iggy/_meta"
    assert_not_equal original, @response.body

    get "/source/home:Iggy/_meta?view=flagdetails"
    assert_response :success

  end

  def test_package_remove_flag
    prepare_request_with_user "Iggy", "asdfasdf"

    get "/source/home:Iggy/TestPack/_meta"
    assert_response :success
    original = @response.body

    post "/source/home:unknown/Nothere?cmd=remove_flag&repository=10.2&arch=i586&flag=build"
    assert_response 404
    assert_match(/unknown_project/, @response.body)

    post "/source/home:Iggy/Nothere?cmd=remove_flag&repository=10.2&arch=i586"
    assert_response 404
    assert_match(/unknown_package/, @response.body)

    post "/source/home:Iggy/Nothere?cmd=remove_flag&repository=10.2&arch=i586&flag=build"
    assert_response 404
    assert_match(/unknown_package/, @response.body)

    post "/source/home:Iggy/TestPack?cmd=remove_flag&repository=10.2&arch=i586&flag=shine"
    assert_response 400
    assert_match(/Error: unknown flag type 'shine' not found./, @response.body)

    get "/source/home:Iggy/TestPack/_meta"
    assert_response :success
    # so far noting should have changed
    assert_equal original, @response.body

    post "/source/kde4/kdelibs?cmd=remove_flag&repository=10.2&arch=x86_64&flag=debuginfo"
    assert_response 403
    assert_match(/no permission to execute command/, @response.body)

    post "/source/home:Iggy/TestPack?cmd=remove_flag&repository=10.2&arch=x86_64&flag=debuginfo"
    assert_response :success

    get "/source/home:Iggy/TestPack/_meta"
    assert_not_equal original, @response.body

    # non existant repos should not change anything
    original = @response.body

    post "/source/home:Iggy/TestPack?cmd=remove_flag&repository=10.7&arch=x86_64&flag=debuginfo"
    assert_response :success # actually I consider forbidding repositories not existant

    get "/source/home:Iggy/TestPack/_meta"
    assert_equal original, @response.body

    get "/source/home:Iggy/TestPack/_meta?view=flagdetails"
    assert_response :success
  end

  def test_project_remove_flag
    prepare_request_with_user "Iggy", "asdfasdf"

    get "/source/home:Iggy/_meta"
    assert_response :success
    original = @response.body

    post "/source/home:unknown/Nothere?cmd=remove_flag&repository=10.2&arch=i586&flag=build"
    assert_response 404
    assert_match(/unknown_project/, @response.body)

    post "/source/home:Iggy/Nothere?cmd=remove_flag&repository=10.2&arch=i586"
    assert_response 404
    assert_match(/unknown_package/, @response.body)

    post "/source/home:Iggy?cmd=remove_flag&repository=10.2&arch=i586&flag=shine"
    assert_response 400
    assert_match(/Error: unknown flag type 'shine' not found./, @response.body)

    get "/source/home:Iggy/_meta"
    assert_response :success
    # so far noting should have changed
    assert_equal original, @response.body

    post "/source/kde4/kdelibs?cmd=remove_flag&repository=10.2&arch=x86_64&flag=debuginfo"
    assert_response 403
    assert_match(/no permission to execute command/, @response.body)

    post "/source/home:Iggy?cmd=remove_flag&repository=10.2&arch=x86_64&flag=debuginfo"
    assert_response :success

    get "/source/home:Iggy/_meta"
    assert_not_equal original, @response.body

    # non existant repos should not change anything
    original = @response.body

    post "/source/home:Iggy?cmd=remove_flag&repository=10.7&arch=x86_64&flag=debuginfo"
    assert_response :success # actually I consider forbidding repositories not existant

    get "/source/home:Iggy/_meta"
    assert_equal original, @response.body

    get "/source/home:Iggy/_meta?view=flagdetails"
    assert_response :success
  end

  def test_wild_chars
    prepare_request_with_user "Iggy", "asdfasdf"
    get "/source/home:Iggy/TestPack"
    assert_response :success
   
    Suse::Backend.put( '/source/home:Iggy/TestPack/bnc#620675.diff', 'argl')
    assert_response :success

    get "/source/home:Iggy/TestPack"
    assert_response :success

    assert_tag :tag => "directory", :child => { :tag => "entry" }
    assert_tag :tag => "directory",
      :children => { :count => 1, :only => { :tag => "entry", :attributes => { :name => "bnc#620675.diff" } } }

    get "/source/home:Iggy/TestPack/bnc#620675.diff"
    assert_response :success

    #cleanup
    delete "/source/home:Iggy/TestPack/bnc#620675.diff"
    assert_response :success
  end

end
