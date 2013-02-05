class TripTicketCommentsController < ApplicationController
  load_and_authorize_resource :trip_ticket
  load_and_authorize_resource :trip_ticket_comment, :through => :trip_ticket

  # GET /trip_ticket_comments
  # GET /trip_ticket_comments.json
  def index
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @trip_ticket_comments }
    end
  end

  # GET /trip_ticket_comments/1
  # GET /trip_ticket_comments/1.json
  def show
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @trip_ticket_comment }
    end
  end

  # GET /trip_ticket_comments/new
  # GET /trip_ticket_comments/new.json
  def new
    @trip_ticket_comment.user = current_user

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @trip_ticket_comment }
    end
  end

  # GET /trip_ticket_comments/1/edit
  def edit
  end

  # POST /trip_ticket_comments
  # POST /trip_ticket_comments.json
  def create
    @trip_ticket_comment.user = current_user
    
    respond_to do |format|
      if @trip_ticket_comment.save
        format.html { redirect_to [@trip_ticket, @trip_ticket_comment], notice: 'Trip ticket comment was successfully created.' }
        format.json { render json: @trip_ticket_comment, status: :created, location: @trip_ticket_comment }
      else
        format.html { render action: "new" }
        format.json { render json: @trip_ticket_comment.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /trip_ticket_comments/1
  # PUT /trip_ticket_comments/1.json
  def update
    respond_to do |format|
      if @trip_ticket_comment.update_attributes(params[:trip_ticket_comment])
        format.html { redirect_to [@trip_ticket, @trip_ticket_comment], notice: 'Trip ticket comment was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @trip_ticket_comment.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /trip_ticket_comments/1
  # DELETE /trip_ticket_comments/1.json
  def destroy
    @trip_ticket_comment.destroy

    respond_to do |format|
      format.html { redirect_to trip_ticket_trip_ticket_comments_url(@trip_ticket) }
      format.json { head :no_content }
    end
  end
end
