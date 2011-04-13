require 'zip/zip'

class MpxExporter

  attr_accessor :errors

  def initialize( params )#start_date, end_date, reprocess = false )
    @errors = []
    
    sd = params[:start_date]
    @start_date = Time.new( sd[:year], sd[:month], sd[:day], sd[:hour], sd[:minute] )
    
    ed = params[:end_date]
    @end_date   = Time.new( ed[:year], ed[:month], ed[:day], ed[:hour], ed[:minute] )
    
    @reprocess  = params[:reprocess]

    @records = Order.complete.where( [ 'completed_at >= ? AND completed_at <= ?', @start_date, @end_date ] )
  end

  def export
    #Doing this from the controller now.
  end

  def donor_account_data

    csv_string = CSV.generate( { :force_quotes => true } ) do |csv|
      csv << [ "cstAcctNbr", "lnkAcctNbr", "DonorTitleName", "DonorFirstName", "DonorMI", "DonorLastName", "DonorSuffix", "SpouseFirstName", "OrganizationName", "AddressLines", "City", "State", "Zip", "County", "Country", "cstAddDate", "cstUserID", "cstSourceCode" ]
      

      @records.each do |record|
        csv << [
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
          record.bill_address.city,
          record.bill_address.state.name,
          record.bill_address.zipcode,
          '',                                                                             # Always ''
          record.bill_address.country.name,
          record.completed_at,
          '',                                                                             # Always ''
          ''                                                                              # Always ''
        ]
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
        csv << [
          record.number,
          ( record.user.nil? || record.user.has_role?( 'staff' ) ) ? record.email : record.user.id,  # User.id unless There is no user or it's a staff user, then email
          '',                                                                                        # Always ''
          record.completed_at,
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
          0, #TODO: gift_amount,
          '',                                                                                        # Always ''
          '',                                                                                        # Always ''
          '',                                                                                        # Always ''
          '',                                                                                        # Always ''
          '',                                                                                        # Always ''
          '',                                                                                        # Always ''
          #TODO: This probably needs some tweaking:
          '' #record.payments.first.source_type
        ]
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
        order.line_items.each do |record|
          csv << [
            order.number,
            record.price,
            'WM',
            record.variant.sku,                                                                        # Code
            '',                                                                                        # Always ''
            '',                                                                                        # Always ''
            ''                                                                                         # Always ''
          ]
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
      csv << [ "lnkOrdRef", "lnkAcctNbr", "OrderDate", "PayMethodCode", "payment_method", "CCType", "CCExpiry", "PayRefNum", "CCAuth", "CCAuthDate", "CurrencyCode", "MediaCode", "MotivationCode", "PurchaseLocation", "FreeLocation", "Comment", "TotalFunds", "TotalDiscounts", "ShipperTotal", "Discount", "OrderTax", "Ship_Name", "Ship_AddressLines", "Ship_City", "Ship_State", "Ship_Zip", "ShipCounty", "ShipperCode", "BatchType", "GiftMotvCode", "GiftPledgeCode", "GiftFundID" ]

      @records.each do |record|
        csv << [
          record.number,
          ( record.user.nil? || record.user.has_role?( 'staff' ) ) ? record.email : record.user.id,  # User.id unless There is no user or it's a staff user, then email
          record.completed_at,
          "Web Authorized", 
          #TODO: This probably needs some tweaking:
          '', #record.payments.first.source_type,
          '',                                                                                        # Always ''
          '',                                                                                        # Always ''
          '',                                                                                        # Always ''
          '',                                                                                        # Always ''
          '',                                                                                        # Always ''
          'USD',                                                                                     # Always 'USD'
          '',                                                                                        # Always ''
          'WM',                                                                                      # Always 'WM'
          "TODO: PurchaseLocation", 
          "TODO: FreeLocation", 
          "", 
          record.total,                                                                              # "TotalFunds", 
          record.credit_total,                                                                       # "TotalDiscounts", 
          record.ship_total,                                                                         # "ShipperTotal", 
          0, #TODO: record.coupon_total,                                                                       # TODO: Supposed to be coupons only. "Discount", 
          record.tax_total,                                                                          # "OrderTax", 
          record.ship_address.full_name, #"Ship_Name", 
          record.ship_address.address1 + "<BR>" + record.ship_address.address2, #"Ship_AddressLines", 
          record.ship_address.city, #"Ship_City", 
          record.ship_address.state.name, #"Ship_State", 
          record.ship_address.zipcode, #"Ship_Zip", 
          '', #"ShipCounty", 
          '', #TODO: Add this: record.shipments.first.shipping_method.mpx_code, #"ShipperCode", 
          '', #"BatchType", 
          'WM', # TODO: Is this right? "GiftMotvCode", 
          '', #"GiftPledgeCode",
          '' #TODO: This is supposed to be the mpx code of the first donation in the order only.. So weird.
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
      csv << [ "lnkOrdRef", "ProdCode", "PriceCode", "Price", "PurQty", "FreeQty", "Tax", "SecondTax", "Taxable", "code_override" ]

      @records.each do |order|
        order.line_items.each do |line_item|
          csv << [
            order.number,
            line_item.variant.sku,
            'ST',
            line_item.price,
            line_item.quantity,
            '',
            0, 
            0, 
            0, #TODO: Taxable
            line_item.variant.sku # We shouldn't need a code override anymore since we have variants.
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
