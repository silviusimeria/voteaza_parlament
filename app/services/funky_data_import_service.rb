class FunkyDataImportService

  LINK_MAPPINGS = {
    'Link CV' => 'cv',
    'Cont Facebook' => 'facebook',
    'Cont Instagram' => 'instagram',
    'Cont Tiktok' => 'tiktok',
    'Link spre declarație de avere' => 'asset_declaration',
    'Link spre declarația de interese' => 'interests_declaration',
    'Link către biblioteca de reclame' => 'ad_library',
  }.freeze

  POSITION_MAPPINGS = {
    'development' => 'Poziție dezvoltare',
    'ukraine' => 'Poziție Ucraina',
    'eu' => 'Poziție pro/anti',
    'climate' => 'Poziție schimbări climatice',
    'corruption' => 'Declarație anticorupție',
    'lgbt' => 'Declarație LGBT',
    'inflation' => 'Poziție inflație și costul vieții'
  }.freeze

  def self.import(data)
    data.each do |row|
      # Store the entire row as JSON
      person = Person.find_or_create_by!(name: row['Nume candidat']) do |p|
        p.funky_data = row # Store complete row data
      end

      # Import all links
      import_links(person, row)
    end
  end

  private

  def self.import_links(person, row)
    # Map CSV columns to link types

    # Handle regular links
    LINK_MAPPINGS.each do |csv_column, kind|
      import_link(person, kind, row[csv_column])
    end

    POSITION_MAPPINGS.each do |topic, column|
      import_position_statement(person, topic, row[column])
    end
  end

  def self.import_link(person, kind, url_data, official: nil)
    return if url_data.blank?

    urls = if url_data.is_a?(String)
             url_data.include?(',') ? url_data.split(',').map(&:strip) : [url_data]
           else
             Array(url_data)
           end

    urls.each do |single_url|
      next unless single_url.start_with?('http')

      # Don't create duplicate links
      person.people_links.find_or_create_by!(
        kind: kind,
        url: single_url
      ) do |link|
        link.official = official unless official.nil?
      end
    end
  end

  def self.import_position_statement(person, topic, content)
    return if content.blank?

    if content.start_with?('http')
      person.people_links.find_or_create_by!(
        kind: 'position_statement',
        url: content
      ) do |link|
        link.official = true
      end
    end
  end

  def self.extract_valid_url(content)
    URI.extract(content).find { |url| url.start_with?('http') }
  rescue URI::InvalidURIError
    nil
  end

  def self.parse_date(date_string)
    return nil if date_string.blank?
    Date.strptime(date_string, '%m/%d/%y')
  rescue Date::Error
    nil
  end
end