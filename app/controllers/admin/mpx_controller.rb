class Admin::MpxController < Admin::BaseController

  def show
  end

  def index
  end

  def export
    e = MpxExporter.new(params)
    
    if @test_output = e.export
      flash[:notice] = "Exported Successfully!"
    else
      flash[:error]  = "There was a problem exporting the data:\n" + e.errors.join( "\n" )
    end

    render 'show'
  end

end
