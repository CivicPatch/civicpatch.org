module StaticOpenDataHelper
  def initials_for(name)
    return '??' unless name&.strip&.present?
    parts = name.strip.split(/\s+/)
    parts.size >= 2 ? (parts[0][0] + parts[-1][0]).upcase : parts[0][0].upcase * 2
  end

  def office_text_for(rep)
    rep['roles'].is_a?(Array) && rep['roles'].any? ? rep['roles'].join(', ') : 'N/A'
  end

  def other_names_for(rep)
    return [] unless rep['other_names']&.is_a?(Array) && rep['other_names'].any?
    rep['other_names'].map { |name| 
      name.is_a?(String) ? name : (name.is_a?(Hash) && name['name'] ? name['name'] : name.to_s)
    }
  end

  def email_for(rep)
    rep['email'] || rep['contact_email']
  end

  def phone_for(rep)
    rep['phone_number']
  end

  def all_links_for(rep)
    all_links = []
    
    website = rep['website'] || rep['url'] || rep['official_website']
    if website&.present?
      href = website.match(/^https?:\/\//) ? website : "https://#{website}"
      all_links << { url: href, label: 'Website' }
    end
    
    if rep['links']&.is_a?(Array)
      rep['links'].each do |link|
        if link.is_a?(String)
          all_links << { url: link, label: 'Link' }
        elsif link.is_a?(Hash) && link['url']
          all_links << { url: link['url'], label: link['note'] || link['label'] || 'Link' }
        end
      end
    end
   
    # TBD figure out if we want to display this
    # if rep['sources']&.is_a?(Array)
    #   rep['sources'].each do |source|
    #     if source.is_a?(String)
    #       all_links << { url: source, label: 'Source' }
    #     elsif source.is_a?(Hash) && source['url']
    #       all_links << { url: source['url'], label: source['note'] || source['label'] || 'Source' }
    #     end
    #   end
    # end
    
    all_links
  end
end