# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

[ :site_admin, :provider_admin, :scheduler, :dispatcher, :csr ].each do |r|
  Role.find_or_create_by_name(r)
end

[
  'African American',
  'American Indian/Alaska Native',
  'Asian Indian',
  'Asian',
  'Caucasian',
  'Chinese',
  'Filipino',
  'Guamanian or Chamorro',
  'Hispanic',
  'Japanese',
  'Korean',
  'Native Hawaiian',
  'Other',
  'Pacific Islander',
  'Refused',
  'Russian',
  'Samoan',
  'Unknown',
  'Vietnamese',
].each do |e|
  Ethnicity.find_or_create_by_name(e)
end
