class StaticPagesController < ApplicationController
  def index

  end

  def contact
    ContactMailer.contact(params[:name], params[:email], params[:body]).deliver_now

    redirect_to root_url
  end
end
