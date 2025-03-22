class Api::RepresentativesController < ApplicationController
  def index
    # representatives = Representative.all
    # render json: representatives
    render json: { message: "Hello, world!" }
  end
end
