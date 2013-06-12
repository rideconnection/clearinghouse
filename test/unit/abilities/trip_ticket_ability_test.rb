require 'test_helper'

class TripTicketAbilityTest < ActiveSupport::TestCase
  setup do
    @roles = {
      :site_admin     => FactoryGirl.create(:role, :name => "site_admin"),
      :provider_admin => FactoryGirl.create(:role, :name => "provider_admin"),
      :scheduler      => FactoryGirl.create(:role, :name => "scheduler"),
      :dispatcher     => FactoryGirl.create(:role, :name => "dispatcher"),
      :read_only      => FactoryGirl.create(:role, :name => "read_only")
    }

    @provider_1 = FactoryGirl.create(:provider)
    @provider_2 = FactoryGirl.create(:provider)
    @provider_3 = FactoryGirl.create(:provider)

    @provider_relationship_1 = ProviderRelationship.create!(:requesting_provider => @provider_1, :cooperating_provider => @provider_2)
    @provider_relationship_2 = ProviderRelationship.create!(:requesting_provider => @provider_2, :cooperating_provider => @provider_3)
    @provider_relationship_3 = ProviderRelationship.create!(:requesting_provider => @provider_3, :cooperating_provider => @provider_1)
    @provider_relationship_1.approve!
    @provider_relationship_2.approve!

    @trip_ticket_1 = FactoryGirl.create(:trip_ticket, :originator => @provider_1)
    @trip_ticket_2 = FactoryGirl.create(:trip_ticket, :originator => @provider_2)
    @trip_ticket_3 = FactoryGirl.create(:trip_ticket, :originator => @provider_3)

    # All users can read (search, filter, etc.) trip tickets belonging to their own provider or providers they have an approved relationship with
    # Dispatchers and above can edit/cancel tickets belonging to their own provider
    # Schedulers and above can create trip tickets belonging to their own provider
    # No user can destroy trip tickets

    # TripTicket#provider_white_list and TripTicket.provider_black_list affect
    # ticket visibility on a ticket-by-ticket basis. Only providers that have
    # an approved relationship should appear in these lists, so the permissions
    # should be XAND'd together.
    @trip_ticket_4 = FactoryGirl.create(:trip_ticket, :originator => @provider_2, :provider_black_list => [@provider_1.id])
    @trip_ticket_5 = FactoryGirl.create(:trip_ticket, :originator => @provider_2, :provider_black_list => [@provider_3.id])
    @trip_ticket_6 = FactoryGirl.create(:trip_ticket, :originator => @provider_2, :provider_white_list => [@provider_1.id])
    @trip_ticket_7 = FactoryGirl.create(:trip_ticket, :originator => @provider_2, :provider_white_list => [@provider_3.id])
    
    # Testing against ticket #1367
    @trip_ticket_8 = FactoryGirl.create(:trip_ticket, :originator => @provider_1, :provider_black_list => [@provider_2.id])    
    @trip_ticket_9 = FactoryGirl.create(:trip_ticket, :originator => @provider_1, :provider_white_list => [@provider_2.id])    
  end

  describe "site_admin role" do
    setup do
      @current_user = FactoryGirl.create(:user, :provider => @provider_1)
      @current_user.role = @roles[:site_admin]
      @site_admin = Ability.new(@current_user)
    end

    it "can use accessible_by to find trip tickets belonging to their own provider or providers they have an approved relationship with" do
      accessible = TripTicket.accessible_by(@site_admin)
      accessible.must_include @trip_ticket_1
      accessible.must_include @trip_ticket_2
      accessible.wont_include @trip_ticket_3
      accessible.wont_include @trip_ticket_4
      accessible.must_include @trip_ticket_5
      accessible.must_include @trip_ticket_6
      accessible.wont_include @trip_ticket_7
      accessible.must_include @trip_ticket_8
      accessible.must_include @trip_ticket_9
    end
  
    it "can create trip tickets belonging to their own provider" do
      assert @site_admin.cannot?(:create, TripTicket.new)
      assert @site_admin.can?(:create, TripTicket.new(:origin_provider_id => @provider_1.id))  
      assert @site_admin.cannot?(:create, TripTicket.new(:origin_provider_id => @provider_2.id))
      assert @site_admin.cannot?(:create, TripTicket.new(:origin_provider_id => @provider_3.id))
    end
  
    it "can read trip tickets belonging to their own provider or providers they have an approved relationship with" do
      assert @site_admin.can?(:read, @trip_ticket_1)
      assert @site_admin.can?(:read, @trip_ticket_2)
      assert @site_admin.cannot?(:read, @trip_ticket_3)
      assert @site_admin.cannot?(:read, @trip_ticket_4)
      assert @site_admin.can?(:read, @trip_ticket_5)
      assert @site_admin.can?(:read, @trip_ticket_6)
      assert @site_admin.cannot?(:read, @trip_ticket_7)
      assert @site_admin.can?(:read, @trip_ticket_8)
      assert @site_admin.can?(:read, @trip_ticket_9)
    end
  
    it "can update trip tickets belonging to their own provider" do
      assert @site_admin.can?(:update, @trip_ticket_1)
      assert @site_admin.cannot?(:update, @trip_ticket_2)
      assert @site_admin.cannot?(:update, @trip_ticket_3)
      assert @site_admin.can?(:update, @trip_ticket_8)
      assert @site_admin.can?(:update, @trip_ticket_9)
    end
  
    it "cannot destroy any trip tickets" do
      assert @site_admin.cannot?(:destroy, @trip_ticket_1)
      assert @site_admin.cannot?(:destroy, @trip_ticket_2)  
      assert @site_admin.cannot?(:destroy, @trip_ticket_3)
      assert @site_admin.cannot?(:destroy, @trip_ticket_8)
      assert @site_admin.cannot?(:destroy, @trip_ticket_9)
    end

    it "can rescind trip tickets belonging to their own provider" do
      assert @site_admin.can?(:rescind, @trip_ticket_1)
      assert @site_admin.cannot?(:rescind, @trip_ticket_2)
      assert @site_admin.cannot?(:rescind, @trip_ticket_3)
      assert @site_admin.can?(:rescind, @trip_ticket_8)
      assert @site_admin.can?(:rescind, @trip_ticket_9)
    end
  end

  describe "provider_admin role" do
    setup do
      @current_user = FactoryGirl.create(:user, :provider => @provider_1)
      @current_user.role = @roles[:provider_admin]
      @provider_admin = Ability.new(@current_user)
    end
  
    it "can use accessible_by to find trip tickets belonging to their own provider or providers they have an approved relationship with" do
      accessible = TripTicket.accessible_by(@provider_admin)
      accessible.must_include @trip_ticket_1
      accessible.must_include @trip_ticket_2
      accessible.wont_include @trip_ticket_3
      accessible.wont_include @trip_ticket_4
      accessible.must_include @trip_ticket_5
      accessible.must_include @trip_ticket_6
      accessible.wont_include @trip_ticket_7
      accessible.must_include @trip_ticket_8
      accessible.must_include @trip_ticket_9
    end
  
    it "can create trip tickets belonging to their own provider" do
      assert @provider_admin.cannot?(:create, TripTicket.new)
      assert @provider_admin.can?(:create, TripTicket.new(:origin_provider_id => @provider_1.id))  
      assert @provider_admin.cannot?(:create, TripTicket.new(:origin_provider_id => @provider_2.id))
      assert @provider_admin.cannot?(:create, TripTicket.new(:origin_provider_id => @provider_3.id))
    end
  
    it "can read trip tickets belonging to their own provider or providers they have an approved relationship with" do
      assert @provider_admin.can?(:read, @trip_ticket_1)
      assert @provider_admin.can?(:read, @trip_ticket_2)
      assert @provider_admin.cannot?(:read, @trip_ticket_3)
      assert @provider_admin.cannot?(:read, @trip_ticket_4)
      assert @provider_admin.can?(:read, @trip_ticket_5)
      assert @provider_admin.can?(:read, @trip_ticket_6)
      assert @provider_admin.cannot?(:read, @trip_ticket_7)
      assert @provider_admin.can?(:read, @trip_ticket_8)
      assert @provider_admin.can?(:read, @trip_ticket_9)
    end
  
    it "can update trip tickets belonging to their own provider" do
      assert @provider_admin.can?(:update, @trip_ticket_1)
      assert @provider_admin.cannot?(:update, @trip_ticket_2)
      assert @provider_admin.cannot?(:update, @trip_ticket_3)
      assert @provider_admin.can?(:update, @trip_ticket_8)
      assert @provider_admin.can?(:update, @trip_ticket_9)
    end
  
    it "cannot destroy any trip tickets" do
      assert @provider_admin.cannot?(:destroy, @trip_ticket_1)
      assert @provider_admin.cannot?(:destroy, @trip_ticket_2)  
      assert @provider_admin.cannot?(:destroy, @trip_ticket_3)
      assert @provider_admin.cannot?(:destroy, @trip_ticket_8)
      assert @provider_admin.cannot?(:destroy, @trip_ticket_9)
    end

    it "can rescind trip tickets belonging to their own provider" do
      assert @provider_admin.can?(:rescind, @trip_ticket_1)
      assert @provider_admin.cannot?(:rescind, @trip_ticket_2)
      assert @provider_admin.cannot?(:rescind, @trip_ticket_3)
      assert @provider_admin.can?(:rescind, @trip_ticket_8)
      assert @provider_admin.can?(:rescind, @trip_ticket_9)
    end
  end
  
  describe "scheduler role" do
    setup do
      @current_user = FactoryGirl.create(:user, :provider => @provider_1)
      @current_user.role = @roles[:scheduler]
      @scheduler = Ability.new(@current_user)
    end

    it "can use accessible_by to find trip tickets belonging to their own provider or providers they have an approved relationship with" do
      accessible = TripTicket.accessible_by(@scheduler)
      accessible.must_include @trip_ticket_1
      accessible.must_include @trip_ticket_2
      accessible.wont_include @trip_ticket_3
      accessible.wont_include @trip_ticket_4
      accessible.must_include @trip_ticket_5
      accessible.must_include @trip_ticket_6
      accessible.wont_include @trip_ticket_7
      accessible.must_include @trip_ticket_8
      accessible.must_include @trip_ticket_9
    end

    it "can create trip tickets belonging to their own provider" do
      assert @scheduler.cannot?(:create, TripTicket.new)
      assert @scheduler.can?(:create, TripTicket.new(:origin_provider_id => @provider_1.id))  
      assert @scheduler.cannot?(:create, TripTicket.new(:origin_provider_id => @provider_2.id))
      assert @scheduler.cannot?(:create, TripTicket.new(:origin_provider_id => @provider_3.id))
    end

    it "can read trip tickets belonging to their own provider or providers they have an approved relationship with" do
      assert @scheduler.can?(:read, @trip_ticket_1)
      assert @scheduler.can?(:read, @trip_ticket_2)
      assert @scheduler.cannot?(:read, @trip_ticket_3)
      assert @scheduler.cannot?(:read, @trip_ticket_4)
      assert @scheduler.can?(:read, @trip_ticket_5)
      assert @scheduler.can?(:read, @trip_ticket_6)
      assert @scheduler.cannot?(:read, @trip_ticket_7)
      assert @scheduler.can?(:read, @trip_ticket_8)
      assert @scheduler.can?(:read, @trip_ticket_9)
    end

    it "can update trip tickets belonging to their own provider" do
      assert @scheduler.can?(:update, @trip_ticket_1)
      assert @scheduler.cannot?(:update, @trip_ticket_2)
      assert @scheduler.cannot?(:update, @trip_ticket_3)
      assert @scheduler.can?(:update, @trip_ticket_8)
      assert @scheduler.can?(:update, @trip_ticket_9)
    end

    it "cannot destroy any trip tickets" do
      assert @scheduler.cannot?(:destroy, @trip_ticket_1)
      assert @scheduler.cannot?(:destroy, @trip_ticket_2)  
      assert @scheduler.cannot?(:destroy, @trip_ticket_3)
      assert @scheduler.cannot?(:destroy, @trip_ticket_8)
      assert @scheduler.cannot?(:destroy, @trip_ticket_9)
    end

    it "can rescind trip tickets belonging to their own provider" do
      assert @scheduler.can?(:rescind, @trip_ticket_1)
      assert @scheduler.cannot?(:rescind, @trip_ticket_2)
      assert @scheduler.cannot?(:rescind, @trip_ticket_3)
      assert @scheduler.can?(:rescind, @trip_ticket_8)
      assert @scheduler.can?(:rescind, @trip_ticket_9)
    end
  end
  
  describe "dispatcher role" do
    setup do
      @current_user = FactoryGirl.create(:user, :provider => @provider_1)
      @current_user.role = @roles[:dispatcher]
      @dispatcher = Ability.new(@current_user)
    end

    it "can use accessible_by to find trip tickets belonging to their own provider or providers they have an approved relationship with" do
      accessible = TripTicket.accessible_by(@dispatcher)
      accessible.must_include @trip_ticket_1
      accessible.must_include @trip_ticket_2
      accessible.wont_include @trip_ticket_3
      accessible.wont_include @trip_ticket_4
      accessible.must_include @trip_ticket_5
      accessible.must_include @trip_ticket_6
      accessible.wont_include @trip_ticket_7
      accessible.must_include @trip_ticket_8
      accessible.must_include @trip_ticket_9
    end

    it "cannot create trip tickets regardless of provider" do
      assert @dispatcher.cannot?(:create, TripTicket.new)
      assert @dispatcher.cannot?(:create, TripTicket.new(:origin_provider_id => @provider_1.id))  
      assert @dispatcher.cannot?(:create, TripTicket.new(:origin_provider_id => @provider_2.id))
      assert @dispatcher.cannot?(:create, TripTicket.new(:origin_provider_id => @provider_3.id))
    end

    it "can read trip tickets belonging to their own provider or providers they have an approved relationship with" do
      assert @dispatcher.can?(:read, @trip_ticket_1)
      assert @dispatcher.can?(:read, @trip_ticket_2)
      assert @dispatcher.cannot?(:read, @trip_ticket_3)
      assert @dispatcher.cannot?(:read, @trip_ticket_4)
      assert @dispatcher.can?(:read, @trip_ticket_5)
      assert @dispatcher.can?(:read, @trip_ticket_6)
      assert @dispatcher.cannot?(:read, @trip_ticket_7)
      assert @dispatcher.can?(:read, @trip_ticket_8)
      assert @dispatcher.can?(:read, @trip_ticket_9)
    end

    it "can update trip tickets belonging to their own provider" do
      assert @dispatcher.can?(:update, @trip_ticket_1)
      assert @dispatcher.cannot?(:update, @trip_ticket_2)
      assert @dispatcher.cannot?(:update, @trip_ticket_3)
      assert @dispatcher.can?(:update, @trip_ticket_8)
      assert @dispatcher.can?(:update, @trip_ticket_9)
    end

    it "cannot destroy any trip tickets" do
      assert @dispatcher.cannot?(:destroy, @trip_ticket_1)
      assert @dispatcher.cannot?(:destroy, @trip_ticket_2)  
      assert @dispatcher.cannot?(:destroy, @trip_ticket_3)
      assert @dispatcher.cannot?(:destroy, @trip_ticket_8)
      assert @dispatcher.cannot?(:destroy, @trip_ticket_9)
    end

    it "can rescind trip tickets belonging to their own provider" do
      assert @dispatcher.can?(:rescind, @trip_ticket_1)
      assert @dispatcher.cannot?(:rescind, @trip_ticket_2)
      assert @dispatcher.cannot?(:rescind, @trip_ticket_3)
      assert @dispatcher.can?(:rescind, @trip_ticket_8)
      assert @dispatcher.can?(:rescind, @trip_ticket_9)
    end
  end

  describe "read_only role" do
    setup do
      @current_user = FactoryGirl.create(:user, :provider => @provider_1)
      @current_user.role = @roles[:read_only]
      @read_only = Ability.new(@current_user)
    end

    it "can use accessible_by to find trip tickets belonging to their own provider or providers they have an approved relationship with" do
      accessible = TripTicket.accessible_by(@read_only)
      accessible.must_include @trip_ticket_1
      accessible.must_include @trip_ticket_2
      accessible.wont_include @trip_ticket_3
      accessible.wont_include @trip_ticket_4
      accessible.must_include @trip_ticket_5
      accessible.must_include @trip_ticket_6
      accessible.wont_include @trip_ticket_7
      accessible.must_include @trip_ticket_8
      accessible.must_include @trip_ticket_9
    end

    it "cannot create trip tickets regardless of provider" do
      assert @read_only.cannot?(:create, TripTicket.new)
      assert @read_only.cannot?(:create, TripTicket.new(:origin_provider_id => @provider_1.id))  
      assert @read_only.cannot?(:create, TripTicket.new(:origin_provider_id => @provider_2.id))
      assert @read_only.cannot?(:create, TripTicket.new(:origin_provider_id => @provider_3.id))
    end

    it "can read trip tickets belonging to their own provider or providers they have an approved relationship with" do
      assert @read_only.can?(:read, @trip_ticket_1)
      assert @read_only.can?(:read, @trip_ticket_2)
      assert @read_only.cannot?(:read, @trip_ticket_3)
      assert @read_only.cannot?(:read, @trip_ticket_4)
      assert @read_only.can?(:read, @trip_ticket_5)
      assert @read_only.can?(:read, @trip_ticket_6)
      assert @read_only.cannot?(:read, @trip_ticket_7)
      assert @read_only.can?(:read, @trip_ticket_8)
      assert @read_only.can?(:read, @trip_ticket_9)
    end

    it "cannot update trip tickets regardless of provider" do
      assert @read_only.cannot?(:update, @trip_ticket_1)
      assert @read_only.cannot?(:update, @trip_ticket_2)
      assert @read_only.cannot?(:update, @trip_ticket_3)
      assert @read_only.cannot?(:update, @trip_ticket_8)
      assert @read_only.cannot?(:update, @trip_ticket_9)
    end

    it "cannot destroy any trip tickets" do
      assert @read_only.cannot?(:destroy, @trip_ticket_1)
      assert @read_only.cannot?(:destroy, @trip_ticket_2)  
      assert @read_only.cannot?(:destroy, @trip_ticket_3)
      assert @read_only.cannot?(:destroy, @trip_ticket_8)
      assert @read_only.cannot?(:destroy, @trip_ticket_9)
    end

    it "cannot rescind trip tickets regardless of provider" do
      assert @read_only.cannot?(:rescind, @trip_ticket_1)
      assert @read_only.cannot?(:rescind, @trip_ticket_2)
      assert @read_only.cannot?(:rescind, @trip_ticket_3)
      assert @read_only.cannot?(:rescind, @trip_ticket_8)
      assert @read_only.cannot?(:rescind, @trip_ticket_9)
    end
  end
end
