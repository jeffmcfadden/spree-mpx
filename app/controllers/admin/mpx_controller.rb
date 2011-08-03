# encoding: utf-8
class Admin::MpxController < Admin::BaseController

  def show
  end

  def index
  end

  def export
    mpx_exporter = MpxExporter.new(params)

    zip_file_name = "mpx_export_#{Time.now.strftime('%Y%m%d%k%M%S')}.zip"
    zip_temp_file = Tempfile.new(zip_file_name)

    Zip::ZipOutputStream.open(zip_temp_file.path) do |zip|
      [:donor_account_data, :donor_email_data, :gift_master_data, :gift_detail_data, :order_master_data, :order_detail_data].each do |file_to_export|
        csv_file_name = file_to_export.to_s.titleize.gsub(/ Data/, '').gsub(' ', '_').gsub('Email', 'EMailAddress') + ".csv" #Generates file names as requested

        csv_temp_file = Tempfile.new(csv_file_name)
        csv_temp_file.write(mpx_exporter.send(file_to_export))
        csv_temp_file.fsync

        zip.put_next_entry(csv_file_name)
        zip.write IO.read(csv_temp_file.path)

        csv_temp_file.close
      end
    end

    send_file zip_temp_file.path, :filename => zip_file_name, :type => 'application/zip', :disposition => 'attachment'
                           
    zip_temp_file.close
    

    
    #@test_data =  donor_account_data        + "\n"
    #@test_data += donor_email_data          + "\n"
    #@test_data += gift_master_data          + "\n"
    #@test_data += gift_detail_data          + "\n"
    #@test_data += order_master_data         + "\n"
    #@test_data += order_detail_data         + "\n"

    #@errors += ["Something went wrong"] #test
    #return @test_data
    
    return
    


    
    # if @test_output = e.export
      # flash[:notice] = "Exported Successfully!"
    # else
      # flash[:error]  = "There was a problem exporting the data:\n" + e.errors.join( "\n" )
    # end

    # render 'show'
  end

end
