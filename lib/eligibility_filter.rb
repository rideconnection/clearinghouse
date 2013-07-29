require 'active_support/concern'

module EligibilityFilter
  extend ActiveSupport::Concern

  protected

  def service_eligibility_filter(service)
    query_str = ""
    query_params = []
    service.eligibility_requirements.each do |requirement|
      # within a service
      # filter for eligibility requirement met OR eligibility requirement met OR etc.
      new_sql, new_params = eligibility_requirement_filter(requirement)
      if new_sql.present?
        query_str << " OR " if query_str.present?
        query_str << "(#{new_sql})"
        query_params = query_params + new_params
      end
    end
    return query_str, query_params
  end

  def eligibility_requirement_filter(requirement)
    join_str = " #{requirement.boolean_type.upcase} "
    query_str = ""
    query_params = []
    requirement.eligibility_rules.each do |rule|
      new_sql, new_params = eligibility_rule_filter(rule)
      if new_sql.present?
        query_str << join_str if query_str.present?
        query_str << "(#{new_sql})"
        query_params = query_params + new_params
      end
    end
    return query_str, query_params
  end

  def eligibility_rule_filter(rule)
    query_str = ""
    query_params = []
    case rule.trip_field
      when 'customer_dob'
        # convert specified age to dates in the past and compare to date of birth field
        age_target = rule.comparison_value.to_i
        less_than_dob = age_target.years.ago.midnight + 1.day
        greater_than_dob = (age_target + 1).years.ago.midnight + 1.day
        case rule.comparison_type
          when 'equal'
            query_str = %Q{("trip_tickets"."customer_dob" IS NOT NULL) AND ("trip_tickets"."customer_dob" < ?) AND ("trip_tickets"."customer_dob" >= ?)}
            query_params = [ less_than_dob, greater_than_dob ]
          when 'not_equal'
            query_str = %Q{("trip_tickets"."customer_dob" IS NULL) OR ("trip_tickets"."customer_dob" >= ?) OR ("trip_tickets"."customer_dob" < ?)}
            query_params = [ less_than_dob, greater_than_dob ]
          when 'greater_than'
            query_str = %Q{("trip_tickets"."customer_dob" IS NOT NULL) AND ("trip_tickets"."customer_dob" < ?)}
            query_params = [ greater_than_dob ]
          when 'less_than'
            query_str = %Q{("trip_tickets"."customer_dob" IS NOT NULL) AND ("trip_tickets"."customer_dob" >= ?)}
            query_params = [ less_than_dob ]
        end
      when *TripTicket::CUSTOMER_IDENTIFIER_ARRAY_FIELDS.stringify_keys.keys
        # array columns
        case rule.comparison_type
          when 'contain'
            query_str = %Q{lower("trip_tickets"."#{rule.trip_field}"::text) LIKE ?}
            query_params = [ "%#{rule.comparison_value.downcase}%" ]
          when 'not_contain'
            query_str = %Q{("trip_tickets"."#{rule.trip_field}" IS NULL) OR (lower("trip_tickets"."#{rule.trip_field}"::text) NOT LIKE ?)}
            query_params = [ "%#{rule.comparison_value.downcase}%" ]
          when 'equal'
            query_str = %Q{? = ANY (lower("trip_tickets"."#{rule.trip_field}"::text)::text[])}
            query_params = [ rule.comparison_value.downcase ]
          when 'not_equal'
            query_str = %Q{("trip_tickets"."#{rule.trip_field}" IS NULL) OR (? != ALL (lower("trip_tickets"."#{rule.trip_field}"::text)::text[]))}
            query_params = [ rule.comparison_value.downcase ]
        end
      else
        # normal columns
        case rule.comparison_type
          when 'contain'
            query_str = %Q{lower("trip_tickets"."#{rule.trip_field}") LIKE ?}
            query_params = [ "%#{rule.comparison_value.downcase}%" ]
          when 'not_contain'
            query_str = %Q{("trip_tickets"."#{rule.trip_field}" IS NULL) OR (lower("trip_tickets"."#{rule.trip_field}") NOT LIKE ?)}
            query_params = [ "%#{rule.comparison_value.downcase}%" ]
          when 'equal'
            query_str = %Q{lower("trip_tickets"."#{rule.trip_field}") = ?}
            query_params = [ rule.comparison_value.downcase ]
          when 'not_equal'
            query_str = %Q{("trip_tickets"."#{rule.trip_field}" IS NULL) OR (lower("trip_tickets"."#{rule.trip_field}") = ?)}
            query_params = [ rule.comparison_value.downcase ]
          when 'greater_than'
            query_str = %Q{("trip_tickets"."#{rule.trip_field}" IS NOT NULL) AND ("trip_tickets"."#{rule.trip_field}" > ?)}
            query_params = [ rule.comparison_value.downcase ]
          when 'less_than'
            query_str = %Q{("trip_tickets"."#{rule.trip_field}" IS NOT NULL) AND ("trip_tickets"."#{rule.trip_field}" < ?)}
            query_params = [ rule.comparison_value.downcase ]
        end
    end
    return query_str, query_params
  end
end
