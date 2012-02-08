require 'zip/zip'
require 'csv'

class MpxExporter

  attr_accessor :errors

  def initialize( params )#start_date, end_date, reprocess = false )
    @errors = []
    
    sd = params[:start_date]
    @start_date = Time.new( sd[:year], sd[:month], sd[:day], sd[:hour], sd[:minute] )
    
    ed = params[:end_date]
    @end_date   = Time.new( ed[:year], ed[:month], ed[:day], ed[:hour], ed[:minute] )
    
    @reprocess  = params[:reprocess]

    @records = Order.complete.where( [ 'completed_at >= ? AND completed_at < ?', @start_date, @end_date ] )
  end

  def self.map_payment_type( new )
    case new
      when 'Check'
        'Check'
      when 'Cash'
        'Cash'
      when 'Other'
        'Other'
      when 'Creditcard'
        'Credit Card'
    end
  end

  def self.map_shipping_mpx_code( name )
    shipping_codes_map = {
      'USPS First Mail International (2 to 3 weeks)'    => 'FI',
      'USPS Global Express Guaranteed (2 to 3 weeks)'   => 'E',
      'USPS Priority Mail International (2 to 3 weeks)' => 'I',
      'USPS First-Class Mail'                           => 'F',
      'USPS Priority Mail (3 to 5 business days)'       => 'P',
      'USPS Library Mail (5 to 14 business days)'       => 'L',
      'UPS Ground (3 to 7 business days)'               => 'G',
      'UPS Three Day Select (4 to 5 business days)'     => '3',
      'UPS Second Day Air (3 to 4 business days)'       => '2',
      'UPS Next Day Air (2 to 3 business days)'         => 'N'
    }
 
    #Return name if no match because that should, in theory, let the user who is
    #importing to mpx choose from the options that are in mpx to match it there
    shipping_codes_map[name] || name
  end

  def donor_account_data

    csv_string = CSV.generate( { :force_quotes => true } ) do |csv|
      csv << [ "cstAcctNbr", "lnkAcctNbr", "DonorTitleName", "DonorFirstName", "DonorMI", "DonorLastName", "DonorSuffix", "SpouseFirstName", "OrganizationName", "AddressLines", "City", "State", "Zip", "County", "Country", "cstAddDate", "cstUserID", "cstSourceCode" ]
      

      deduped_records = {}
      @records.each do |record|

        #Manipulating city, state and zip codes for countries other than US and Canada
        state = record.bill_address.state ? record.bill_address.state.abbr : record.bill_address.state_name 

        if record.bill_address.country.iso = "US" || record.bill_address.country.iso = "CA"
          city = record.bill_address.city
          zipcode = record.bill_address.zipcode
          if record.bill_address.country.iso == "CA"
            if zipcode.length == 6
              zipcode = zipcode[0..2] + " " + zipcode[3..5]
            elsif zipcode[3] == '-'
              zipcode[3] = ' '
            end
          end
        else
          #Checking to see if we can get state in the city field without it exceeding impact limitations
          if (record.bill_address.city + ' ' + state + ' ' + record.bill_address.zipcode).length > 25 || state.blank? 
            city = record.bill_address.city + ' ' + record.bill_address.zipcode 
          else
            city = record.bill_address.city + ' ' + state + ' ' + record.bill_address.zipcode
          end
          state = ''
          zipcode = ''
        end

        this_row = [
          '',                                                                             # Always ''
          ( record.user.nil? || record.user.has_role?( 'staff' ) ) ? record.email : record.user.id,  # User.id unless There is no user or it's a staff user, then email
          '',                                                                             # Always ''
          record.bill_address.firstname,
          '',                                                                             # Always ''
          record.bill_address.lastname,
          '',                                                                             # Always ''
          '',                                                                             # Always ''
          record.bill_address.organization,
          record.bill_address.address1 + "<BR>" + record.bill_address.address2,
          city,
          state,
          zipcode,
          '',                                                                             # Always ''
          record.bill_address.country.name,
          record.completed_at.strftime( "%Y-%m-%d %k:%M:%S" ),
          '',                                                                             # Always ''
          ''                                                                              # Always ''
        ]

        #Force unique on lnkAcctNbr
        deduped_records[this_row[1]] = this_row
      end

      deduped_records.each do |i, r|
        csv << r
      end
    end
   
    puts csv_string

    return csv_string

    #{
    # :cstAcctNbr",         
    # :lnkAcctNbr",         
    # :DonorTitleName",     # Always ''
    # :DonorFirstName",     # Billing
    # :DonorMI",            # Always ''
    # :DonorLastName",      # Billing
    # :DonorSuffix",        # Always ''
    # :SpouseFirstName",    # Always ''
    # :OrganizationName",   # Billing
    # :AddressLines",       # Billing
    # :City",               # Billing
    # :State",              # Billing
    # :Zip",                # Billing
    # :County",             # Always ''
    # :Country",            # The full country name. i.e. "Angoloa", or "United States"
    # :cstAddDate",         # Order.completed_at
    # :cstUserID",          # Always ''
    # :cstSourceCode        # Always ''
    #}

    #// SEE http://wishbone.evolvs.com/view.php?id=1475
    #// If the account id is empty, use the email address as the unique identifier
    #// If the account id exists, it can only show up a single time in this file and in the email file
    
    #// Get the Data from the order tables
    #//$header = '"cstAcctNbr","lnkAcctNbr","DonorTitleName","DonorFirstName","DonorMI","DonorLastName","DonorSuffix","SpouseFirstName","OrganizationName","AddressLines","City","State","Zip","County","Country","cstAddDate","cstUserID","cstSourceCode"\n';
    #$selectSQL = 
    #//ORDER_HEADER.id as "lnkAcctNbr", 
    #  'SELECT "" as "cstAcctNbr", 

    #    -- If this does not have an account #, or it is a staff account, use email address.
    #    IFNULL(NULLIF((IF((SELECT ACCOUNT_ROLE.ROLE_id FROM ACCOUNT_ROLE WHERE ACCOUNT_ROLE.ACCOUNT_id = ORDER_HEADER.ACCOUNT_id LIMIT 1) = "2", ORDER_HEADER.email_address, ORDER_HEADER.ACCOUNT_id)), 0), ORDER_HEADER.email_address) as "lnkAcctNbr",

    #  "" as "DonorTitleName", 
    #  ORDER_HEADER.billto_first_name as "DonorFirstName", 
    #  "" as "DonorMI", 
    #  ORDER_HEADER.billto_last_name as "DonorLastName", 
    #  "" as "DonorSuffix", 
    #  "" as "SpouseFirstName", 
    #  ORDER_HEADER.billto_company as "OrganizationName", 
    #  CONCAT_WS("<BR>",ORDER_HEADER.billto_address_line1,ORDER_HEADER.billto_address_line2) as "AddressLines", 
    #  ORDER_HEADER.billto_city as "City", 
    #  (SELECT REGION.abbreviation FROM REGION WHERE ORDER_HEADER.billto_REGION_id = REGION.id) as "State", 
    #  ORDER_HEADER.billto_postal as "Zip", 
    #  "" as "County", 
    #  (SELECT COUNTRY.name FROM COUNTRY WHERE ORDER_HEADER.billto_COUNTRY_id = COUNTRY.id) as "Country", 
    #  ORDER_HEADER.ordered_date as "cstAddDate", 
    #  "" as "cstUserID", 
    #  "" as "cstSourceCode"';
    #$fromSQL = ' FROM ORDER_HEADER';
    #$whereSQL = ' WHERE 1';
    #if($startDate) 
    #{
    #  $whereSQL .= " AND ordered_date >= '$startDate'";
    #}
    #if($endDate)
    #{
    #  $whereSQL .= " AND ordered_date <= '$endDate'";
    #}
    #if(!$reprocess)
    #{
    #  $whereSQL .= " AND MPX_processed = FALSE";
    #}
    #$whereSQL .= " AND state <> 'Cart' AND state <> 'Emptied'";
    #//$groupBySQL = ' GROUP BY "AddressLines"';
    #$groupBySQL = ' GROUP BY lnkAcctNbr';
    #$orderBySQL = ' ORDER BY ordered_date';

    #$sql = $selectSQL.$fromSQL.$whereSQL.$groupBySQL.$orderBySQL;
    #//print $sql; exit;
    #$result = EntityDatabase::Construct()->query_assoc_cached($sql);
    #return generateCSV('Donor_Account.csv', $result);
    
  end

  def donor_email_data

    csv_string = CSV.generate( { :force_quotes => true } ) do |csv|
      csv << [ "lnkAcctNbr", "EmailCategory", "EmailAddress" ]
      

      @records.each do |record|
        csv << [
          ( record.user.nil? || record.user.has_role?( 'staff' ) ) ? record.email : record.user.id,   # User.id unless There is no user or it's a staff user, then email
          'EMAIL',                                                                                    # Always 'EMAIL'
          record.email
        ]
      end
    end
   
    puts csv_string

    return csv_string
    


    #{
    # :lnkAcctNbr,     # User.id unless There is no user or it's a staff user, then email
    # :EmailCategory,   # Always 'EMAIL'
    # :EmailAddress,    # User.email
    #}
  end

  def gift_master_data

    csv_string = CSV.generate( { :force_quotes => true } ) do |csv|
      csv << [ "lnkGiftRef", "lnkAcctNbr", "cstGiftRef", "GiftDate", "PayMethodCode", "CCType", "CCExpiry", "PayRefNum", "CCAuth", "CCAuthDate", "ReceiptNumber", "CurrencyCode", "MediaCode", "Comment", "GiftAmt", "MotivationCode", "FundID", "PledgeCode", "Deductible", "Anonymous", "BatchType", "payment_method" ]

      @records.each do |record|
        #We only process orders here where the entire order is made up of
        #donations
        if record.line_items.all? { |line_item| line_item.variant && line_item.variant.product.is_donation_for_mpx? }

          #This might be redundant now
          donations_total = record.line_items.inject(0) {|sum, i| ( i.variant.product.is_donation_for_mpx? ) ? ( sum + i.price ) : 0  }

          csv << [
            record.number,
            ( record.user.nil? || record.user.has_role?( 'staff' ) ) ? record.email : record.user.id,  # User.id unless There is no user or it's a staff user, then email
            '',                                                                                        # Always ''
            record.completed_at.strftime( "%Y-%m-%d %k:%M:%S" ),
            'Web Authorized',                                                                          # Always 'Web Authorized'
            '',                                                                                        # Always ''
            '',                                                                                        # Always ''
            '',                                                                                        # Always ''
            '',                                                                                        # Always ''
            '',                                                                                        # Always ''
            '',                                                                                        # Always ''
            'USD',                                                                                     # Always 'USD'
            '',                                                                                        # Always ''
            '',                                                                                        # Always ''
            donations_total.to_f,                     #but based on the docs the detail export should hold this data, not the master, which overrides
            '',                                                                                        # Always ''
            '',                                                                                        # Always ''
            '',                                                                                        # Always ''
            '',                                                                                        # Always ''
            '',                                                                                        # Always ''
            '',                                                                                        # Always ''
            ( record.payments.first ? MpxExporter.map_payment_type( record.payments.first.source_type ) : '' )
          ]
        end
      end
    end
   
    puts csv_string

    return csv_string
    
    #{
    # :lnkGiftRef,      #Order.id
    # :lnkAcctNbr,      # User.id unless There is no user or it's a staff user, then email
    # :cstGiftRef       # Always ''
		# :GiftDate,        # Order.completed_at
    # :PayMethodCode,   # Always 'Web Authorized'
    # :CCType,          # Always ''
    # :CCExpiry,        # Always ''
    # :PayRefNum,       # Always ''
    # :CCAuth,          # Always ''
    # :CCAuthDate,      # Always ''
    # :ReceiptNumber,   # Always ''
    # :CurrencyCode,    # Always 'USD'
    # :MediaCode,       # Always ''
    # :Comment,         # Always ''
    # :GiftAmt,         # Must be a number
    # :MotivationCode,  # Always ''
    # :FundID,          # Always ''
    # :PledgeCode,      # Always ''
    # :Deductible,      # Always ''
    # :Anonymous,       # Always ''
    # :BatchType,       # Always ''
    # :payment_method,  # 'Credit Card','Check','Cash','Other', or 'ECheck'
    #}
  end

  def gift_detail_data

    csv_string = CSV.generate( { :force_quotes => true } ) do |csv|
      csv << [ "lnkGiftRef", "GiftAmt", "MotivationCode", "FundID", "PledgeCode", "Deductible", "Anonymous" ]

    # :FundID,
    # :PledgeCode,      # Always '' 
    # :Deductible,      # Always ''
    # :Anonymous        # Always ''
      
      @records.each do |order|
        #We only process orders here where the entire order is made up of
        #donations
        if order.line_items.all? { |line_item| line_item.variant && line_item.variant.product.is_donation_for_mpx? }
        
          order.line_items.each do |record|
            #This condition is probably redundant now
            if record.variant && record.variant.product.is_donation_for_mpx?
              csv << [
                order.number,
                record.price,
                'WM',
                record.variant.gift_fund_id,                                                               # Code
                '',                                                                                        # Always ''
                '',                                                                                        # Always ''
                ''                                                                                         # Always ''
              ]
            end
          end
        end
      end
    end
   
    puts csv_string

    return csv_string
    
    #{
    # :lnkGiftRef,      # Order.id
    # :GiftAmt,         # LineItem.price
    # :MotivationCode,  # Always 'WM'
    # :FundID,
    # :PledgeCode,      # Always '' 
    # :Deductible,      # Always ''
    # :Anonymous        # Always ''
    #}
  
  end

  def order_master_data

    csv_string = CSV.generate( { :force_quotes => true } ) do |csv|
      csv << [ "lnkOrdRef", "lnkAcctNbr", "OrderDate", "PayMethodCode", "payment_method", "CCType", "CCExpiry", "PayRefNum", "CCAuth", "CCAuthDate", "CurrencyCode", "MediaCode", "MotivationCode", "PurchaseLocation", "FreeLocation", "Comment", "TotalFunds", "TotalDiscounts", "ShipperTotal", "Discount", "OrderTax", "Ship_Name", "Ship_AddressLines", "Ship_City", "Ship_State", "Ship_Zip", "ShipCountry", "ShipperCode", "BatchType", "GiftMotvCode", "GiftPledgeCode", "GiftFundID" ]

      @records.each do |record|
        #Skip if we have a record with no line items, or one that's only donation(s)
        next if record.line_items.count == 0 || record.line_items.all? { |line_item| line_item.variant.product.is_donation? }
        
        #mpx wants the code of the first donation in the order.
        line_item = record.line_items.detect { |i| i.variant.product.is_donation_for_mpx? }
        first_donation_code = ( line_item && line_item.variant ) ? line_item.variant.gift_fund_id : ''

        #Manipulating city, state and zip codes for countries other than US and Canada
        state = record.ship_address.state ? record.ship_address.state.abbr : record.ship_address.state_name 

        if record.ship_address.country.iso = "US" || record.ship_address.country.iso = "CA"
          city = record.ship_address.city
          zipcode = record.ship_address.zipcode
          if record.ship_address.country.iso == "CA"
            if zipcode.length == 6
              zipcode = zipcode[0..2] + " " + zipcode[3..5]
            elsif zipcode[3] == '-'
              zipcode[3] = ' '
            end
          end
        else
          #Checking to see if we can get state in the city field without it exceeding impact limitations
          if (record.ship_address.city + ' ' + state + ' ' + record.ship_address.zipcode).length > 25 || state.blank? 
            city = record.ship_address.city + ' ' + record.ship_address.zipcode 
          else
            city = record.ship_address.city + ' ' + state + ' ' + record.ship_address.zipcode
          end
          state = ''
          zipcode = ''
        end

        csv << [
          record.number,
          ( record.user.nil? || record.user.has_role?( 'staff' ) ) ? record.email : record.user.id,  # User.id unless There is no user or it's a staff user, then email
          record.completed_at.strftime( "%Y-%m-%d %k:%M:%S" ),
          "Web Authorized", 
          ( record.payments.first ? MpxExporter.map_payment_type( record.payments.first.source_type ) : '' ),
          '',                                                                                        # Always ''
          '',                                                                                        # Always ''
          '',                                                                                        # Always ''
          '',                                                                                        # Always ''
          '',                                                                                        # Always ''
          'USD',                                                                                     # Always 'USD'
          '',                                                                                        # Always ''
          'WM',                                                                                      # Always 'WM'
          "02", 
          "02", 
          "", 
          record.total,                                                                              # "TotalFunds", 
          record.credit_total,                                                                       # "TotalDiscounts", 
          record.ship_total,                                                                         # "ShipperTotal", 
          record.discount_total,                                                                     # Supposed to be coupons only. "Discount", 
          record.tax_total,                                                                          # "OrderTax", 
          record.ship_address.full_name,                                                             #"Ship_Name", 
          record.ship_address.address1 + "<BR>" + record.ship_address.address2,                      #"Ship_AddressLines", 
          city,                                                                                      #manipulated city, 
          state,
          zipcode,                                                                                   #manipulated zip code, 
          record.ship_address.country.name,                                                          #"", 
          ( record.shipments.first ? MpxExporter.map_shipping_mpx_code( record.shipments.first.shipping_method.name ) : '' ),          #"ShipperCode", 
          '',                                                                                        #"BatchType", 
          'WM',                                                                                      # "GiftMotvCode", 
          '',                                                                                        #"GiftPledgeCode",
          first_donation_code                             #This is supposed to be the mpx code of the first donation in the order only.. So weird.
        ]
      end
    end
   
    puts csv_string

    return csv_string
    

    #{
    # :lnkOrdRef,       # Order.id
    # :lnkAcctNbr,      # User.id unless There is no user or it's a staff user, then email
    # :OrderDate,       # Order.completed_at
    # :PayMethodCode,   # Always 'Web Authorized'
    # :payment_method,  # 'Credit Card','Check','Cash','Other', or 'ECheck'
    # :CCType,          # Always ''
    # :CCExpiry,        # Always ''
    # :PayRefNum,       # Always ''
    # :CCAuth,          # Always ''
    # :CCAuthDate,      # Always ''
    # :CurrencyCode,    # Always 'USD'
    # :MediaCode,       # Always ''
    # :MotivationCode,  # Always 'WM'
    # :(IF((SELECT COUNT(ORDER_PRODUCT.ORDER_HEADER_id) FROM ORDER_PRODUCT WHERE ORDER_PRODUCT.ORDER_HEADER_id = ORDER_HEADER.id), "02", "01")) as "PurchaseLocation",
    # :(IF((SELECT COUNT(ORDER_PRODUCT.ORDER_HEADER_id) FROM ORDER_PRODUCT WHERE ORDER_PRODUCT.ORDER_HEADER_id = ORDER_HEADER.id), "02", "01")) as "FreeLocation",
    # :Comment,         # Always ''
    # :TotalFunds,      # Order.total
    # :TotalDiscounts
    # :ShipperTotal
    # :Discount
    # :OrderTax
    # :Ship_Name
    # :Ship_AddressLines
    # :Ship_City
    # :Ship_State
    # :Ship_Zip
    # :ShipCounty
    # :ShipperCode
    # :BatchType,       # Always ''
    # :GiftMotvCode
    # :GiftPledgeCode   # Always ''
    # :GiftFundID
    #}

		
		# "" as "Comment", 
		# ORDER_HEADER.total as "TotalFunds",
		# ((IFNULL(ORDER_HEADER.total_quantity_discounts, 0)) + (IFNULL(ORDER_HEADER.total_coupon_discounts, 0))) AS "TotalDiscounts",
		# (IFNULL(ORDER_HEADER.shipping_cost, 0) + IFNULL(ORDER_HEADER.handling_cost, 0)) as "ShipperTotal", 
		# ORDER_HEADER.total_coupon_discounts as "Discount", 
		# ROUND(IFNULL(ORDER_HEADER.total_tax, 0), 2) as "OrderTax", 
		# CONCAT_WS(" ",ORDER_HEADER.shipto_first_name,ORDER_HEADER.shipto_last_name) as "Ship_Name", '.
    # //		CONCAT_WS("<BR>",ORDER_HEADER.shipto_company,ORDER_HEADER.shipto_address_line1,ORDER_HEADER.shipto_address_line2) as "Ship_AddressLines",
		# '
		# CONCAT_WS("<BR>",CONCAT_WS("<BR>", NULLIF(ORDER_HEADER.shipto_company,""),ORDER_HEADER.shipto_address_line1),ORDER_HEADER.shipto_address_line2) as "Ship_AddressLines", 
		# ORDER_HEADER.shipto_city as "Ship_City", 
		# (SELECT REGION.abbreviation FROM REGION WHERE REGION.id = ORDER_HEADER.shipto_REGION_id) as "Ship_State", 
		# ORDER_HEADER.shipto_postal as "Ship_Zip", 
		# "" as "ShipCounty", 
		# (SELECT COUNTRY.name FROM COUNTRY WHERE COUNTRY.id = ORDER_HEADER.shipto_COUNTRY_id) as "ShipCountry", 
		# (SELECT SHIPPING_METHOD.mpx_code FROM SHIPPING_METHOD WHERE SHIPPING_METHOD.id = ORDER_HEADER.SHIPPING_METHOD_id) as "ShipperCode", 
		# "" as "BatchType", 
		# (SELECT DISTINCT("WM") FROM DONATION WHERE DONATION.ORDER_HEADER_id = ORDER_HEADER.id) as "GiftMotvCode", 
		# "" as "GiftPledgeCode", 
		# (SELECT DISTINCT(DONATION_TYPE.mpx_code) FROM DONATION_TYPE INNER JOIN DONATION ON DONATION.DONATION_TYPE_id = DONATION_TYPE.id WHERE DONATION.ORDER_HEADER_id = ORDER_HEADER.id LIMIT 1) as "GiftFundID"';
    

  end

  def order_detail_data

    csv_string = CSV.generate( { :force_quotes => true } ) do |csv|
      csv << [ "lnkOrdRef", "ProdCode", "PriceCode", "Price", "PurQty", "FreeQty", "Tax", "SecondTax", "Taxable" ]

      
      @records.each do |order|
        order.line_items.each do |line_item|
          #Only non-donation items here
          next if line_item.variant.product.is_donation? || line_item.quantity < 1

          if line_item.variant.product.is_caselot_special? 
            price = '0.00'
          else
            price = sprintf( "%0.2f", ( line_item.amount / line_item.quantity ) ) #Changing because amount takes into account the volume discount. line_item.price
          end

          csv << [
            order.number,
            line_item.variant.sku,
            'ST',
            price,
            line_item.quantity,
            '',
            0, 
            0, 
            ( line_item.variant.product.tax_category && line_item.variant.product.tax_category.name == 'Taxable Goods' ? '1' : '0' ),
          ]
        end
      end
    end
   
    puts csv_string

    return csv_string
    

    #{
    # :lnkOrdRef,     # Order.id
    # :ProdCode,
    # :PriceCode,     # Always 'ST'
    # :Price,         
    # :PurQty,
    # :FreeQty,       # Always ''
    # :Tax,           # 0
    # :SecondTax,     # 0
    # :Taxable,
    # :code_override
    #}

	
    #// Get the Data from the order tables
	  #//$header = '"lnkOrdRef","ProdCode","PriceCode","Price","PurQty","FreeQty","Tax","SecondTax","Taxable"\n';
	  #$selectSQL = 
		#'SELECT ORDER_PRODUCT.ORDER_HEADER_id as "lnkOrdRef",
		#(SELECT PRODUCT.code FROM PRODUCT WHERE PRODUCT.id = ORDER_PRODUCT.PRODUCT_id) as "ProdCode",
		#"ST" as "PriceCode",
		#ORDER_PRODUCT.price as "Price",
		#ORDER_PRODUCT.quantity as "PurQty",
		#"" as "FreeQty",
		#"0" as "Tax",
		#"0" as "SecondTax",
		#ORDER_PRODUCT.taxable as "Taxable",
		#(SELECT PRODUCT_STYLE.code_override FROM PRODUCT_STYLE WHERE PRODUCT_STYLE.id = ORDER_PRODUCT.PRODUCT_STYLE_id) as "code_override"';
	  #$fromSQL = ' FROM ORDER_PRODUCT LEFT JOIN ORDER_HEADER ON ORDER_HEADER.id = ORDER_PRODUCT.ORDER_HEADER_id';
    
  end

end
