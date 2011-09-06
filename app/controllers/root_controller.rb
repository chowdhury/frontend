class RecordNotFound < Exception
end

class RootController < ApplicationController
  include Rack::Geo::Utils
  include RootHelper

  def publication
    @publication = fetch_publication(params)
    assert_found(@publication)

    if @publication.parts
       @partslug = params[:part]
       @part = pick_part(@partslug,@publication)
       assert_found(@part)
    end
    
    instance_variable_set("@#{@publication.type}".to_sym,@publication)
    render @publication.type 
  rescue RecordNotFound
    render :file => "#{Rails.root}/public/404.html", :layout=>nil, :status=>404
  end

  def identify_council
    @transaction = fetch_publication(params)
    assert_found(@transaction && @transaction.type == "local_transaction")
    snac_codes = council_ons_from_geostack
    council = api.council_for_transaction(@transaction,snac_codes)
    redirect_to transaction_path(@slug,council,@edition)
  end

  protected
  def fetch_publication(params)
    @slug = params[:slug]
    options = {}
    if @edition = params[:edition]
      options[:edition] = params[:edition]
    end
    options[:snac] = params[:snac] if params[:snac]
    api.publication_for_slug(@slug,options)
  end

  def council_ons_from_geostack
    geodata = request.env['HTTP_X_GOVGEO_STACK']
    return [] if geodata.nil?
    location_data = decode_stack(geodata)
    if location_data['council']
      snac_codes = location_data['council'].collect do |council|
        council['ons']
      end.compact
    else
      return []
    end
  end


  def assert_found(obj)
    raise RecordNotFound unless obj
  end

  def pick_part(partslug,pub)
     if partslug
        pub.find_part(partslug)
     else
        pub.parts.first
     end
  end
end