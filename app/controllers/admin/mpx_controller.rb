# encoding: utf-8
class Admin::MpxController < Admin::BaseController

  def show
  end

  def index
  end

  def export
    e = MpxExporter.new(params)

    file_name = "mpx_export_#{Time.now.strftime( '%Y%m%d%k%M%S' )}.zip"
    t = Tempfile.new("mpx_export_#{Time.now.strftime( '%Y%m%d%k%M%S' )}")

    Zip::ZipOutputStream.open(t.path) do |z|
      [:donor_account_data, :donor_email_data, :gift_master_data, :gift_detail_data, :order_master_data, :order_detail_data].each do |f|
        tf = Tempfile.new( f.to_s + '.csv' )
        tf.write( e.send( f ) )
        tf.fsync
        z.put_next_entry( f.to_s + '.csv' )
        z.write IO.read( tf.path )
      end
    end

    send_file t.path, :type => 'application/zip',
                           :disposition => 'attachment',
                           :filename => file_name
    t.close
    

    
    #@test_data =  donor_account_data        + "\n"
    #@test_data += donor_email_data          + "\n"
    #@test_data += gift_master_data          + "\n"
    #@test_data += gift_detail_data          + "\n"
    #@test_data += order_master_data         + "\n"
    #@test_data += order_detail_data         + "\n"

    #@errors += ["Something went wrong"] #test
    #return @test_data
    
    return
    


    
    if @test_output = e.export
      flash[:notice] = "Exported Successfully!"
    else
      flash[:error]  = "There was a problem exporting the data:\n" + e.errors.join( "\n" )
    end

    render 'show'
  end

end
