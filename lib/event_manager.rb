require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def clean_phonenumber(phonenumber)
  replacements = {
    "-" => "",
    "(" => "",
    ")" => "",
    "." => "",
    " " => "",
  }

  temp_phonenumber = phonenumber.to_s
  replacements.each do |find, replace|
    temp_phonenumber = temp_phonenumber.gsub(find, replace)
  end

#   temp_phonenumber = temp_phonenumber.strip

  length = temp_phonenumber.length

  if length < 10 || length > 11
    "#{phonenumber} is a bad phone number!"
  elsif length == 11 
    if phonenumber[0] == "1"
        phonenumber = phonenumber[1..]
        "#{phonenumber}"
    elsif phonenumber[0] != "1"
        "#{phonenumber} is a bad phone number!"
    end
  else
    "#{phonenumber}"
  end
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter
hour_array = []
day_of_week_array = []

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  phone_numbers = clean_phonenumber(row[:homephone])

  #Gets the hour for each row in the csv file
  hour = Time.strptime(row[:regdate], "%m/%d/%Y %k:%M").hour
  hour_array.push(hour)

  #Gets the day of the week for each row in the csv file
  day_of_week = Time.strptime(row[:regdate], "%m/%d/%Y %k:%M").wday
  day_of_week_array.push(day_of_week)

  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)
  # puts "#{day_of_week}"

#   form_letter = erb_template.result(binding)
  # puts "#{phone_numbers}"
    # puts "#{date}"
#   save_thank_you_letter(id,form_letter)
end

#Prints a tally of the total hours
puts "Hours people registered:"
puts hour_array.tally

puts "\n----------------------------------\n"

#Prints a tally of the days of the week people registered.
puts "Days of the week that people registered:"
puts day_of_week_array.tally
