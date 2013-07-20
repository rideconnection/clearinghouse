module EligibilityFilter
  protected

  def provider_eligibility_filter(collection, provider)
    collection ||= TripTicket.all
    query_str = ""
    query_params = []
    provider.services.each do |service|
      service.eligibility_requirements.each do |requirement|
        new_sql, new_params = eligibility_requirement_filter(requirement)
        if new_sql.present?
          query_str << " OR " if query_str.present?
          query_str << new_sql
          query_params = query_params + new_params
        end
      end
    end
    query_str.blank? ? collection : collection.where(query_str, *query_params)
  end

  def eligibility_requirement_filter(requirement)
    join_str = " #{requirement.boolean_type.upcase} "
    query_str = ""
    query_params = []
    requirement.eligibility_rules.each do |rule|
      new_sql, new_params = eligibility_rule_filter(rule)
      if new_sql.present?
        query_str << join_str if query_str.present?
        query_str << new_sql
        query_params = query_params + new_params
      end
    end
    return "(#{query_str})", query_params
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
            query_str = "(trip_tickets.customer_dob IS NOT NULL) AND (trip_tickets.customer_dob < ?) AND (trip_tickets.customer_dob >= ?)"
            query_params = [ less_than_dob, greater_than_dob ]
          when 'not_equal'
            query_str = "(trip_tickets.customer_dob IS NULL) OR (trip_tickets.customer_dob >= ?) OR (trip_tickets.customer_dob < ?)"
            query_params = [ less_than_dob, greater_than_dob ]
          when 'greater_than'
            query_str = "(trip_tickets.customer_dob IS NOT NULL) AND (trip_tickets.customer_dob < ?)"
            query_params = [ greater_than_dob ]
          when 'less_than'
            query_str = "(trip_tickets.customer_dob IS NOT NULL) AND (trip_tickets.customer_dob >= ?)"
            query_params = [ less_than_dob ]
        end
      when *TripTicket::CUSTOMER_IDENTIFIER_ARRAY_FIELDS.stringify_keys.keys
        # array columns
        case rule.comparison_type
          when 'contain'
            query_str = "lower(?::text) LIKE ?"
            query_params = [ rule.trip_field, "%#{rule.comparison_value.downcase}%" ]
          when 'not_contain'
            query_str = "(? IS NULL) OR (lower(?::text) NOT LIKE ?)"
            query_params = [ rule.trip_field, rule.trip_field, "%#{rule.comparison_value.downcase}%" ]
          when 'equal'
            query_str = "? = ANY (lower(?::text)::text[])"
            query_params = [ rule.comparison_value.downcase, rule.trip_field ]
          when 'not_equal'
            query_str = "(? IS NULL) OR (? != ALL (lower(?::text)::text[]))"
            query_params = [ rule.trip_field, rule.comparison_value.downcase, rule.trip_field ]
        end
      else
        # normal columns
        case rule.comparison_type
          when 'contain'
            query_str = "lower(?) LIKE ?"
            query_params = [ rule.trip_field, "%#{rule.comparison_value.downcase}%" ]
          when 'not_contain'
            query_str = "(? IS NULL) OR (lower(?) NOT LIKE ?)"
            query_params = [ rule.trip_field, rule.trip_field, "%#{rule.comparison_value.downcase}%" ]
          when 'equal'
            query_str = "lower(?) = ?"
            query_params = [ rule.trip_field, rule.comparison_value.downcase ]
          when 'not_equal'
            query_str = "(? IS NULL) OR (lower(?) = ?)"
            query_params = [ rule.trip_field, rule.trip_field, rule.comparison_value.downcase ]
          when 'greater_than'
            query_str = "(? IS NOT NULL) AND (? > ?)"
            query_params = [ rule.trip_field, rule.trip_field, rule.comparison_value.downcase ]
          when 'less_than'
            query_str = "(? IS NOT NULL) AND (? < ?)"
            query_params = [ rule.trip_field, rule.trip_field, rule.comparison_value.downcase ]
        end
    end
    return "(#{query_str})", query_params
  end
end
