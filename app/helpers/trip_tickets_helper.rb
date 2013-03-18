module TripTicketsHelper
  def providers_from_white_black_list(provider_ids)
    raw Provider.where(:id => provider_ids).all.collect{|p| link_to p.name, provider_path(p)}.join(', ')
  end
end
