class JsonGenerator < Rails::Generators::Base
  source_root File.expand_path("templates", __dir__)

  argument :json_file, type: :string
  attr_reader :json_config, :model_name, :model_name_plural, :model_name_underscore

  def read_file
    data = File.read(json_file)
    @json_config = JSON.parse(data)
    @model_name = @json_config["model_name"]
    @model_name_underscore = @model_name.underscore
    @model_name_plural = @model_name_underscore.pluralize
  end

  def create_model
    template "model.rb.erb", "app/models/#{@model_name_underscore}.rb"
  end

  def create_migration
    template "migration.rb.erb", "db/migrate/#{Time.now.utc.strftime("%Y%m%d%H%M%S")}_create_#{@model_name_plural}.rb"
  end

  def create_controller
    template "controller.rb.erb", "app/controllers/#{@model_name_plural}_controller.rb"
  end

  def add_route
    route "resources :#{@model_name_plural}"
  end

  def create_views
    template "index.html.erb", "app/views/#{model_name_plural}/index.html.erb"
    template "full_table.html.erb", "app/views/#{model_name_plural}/_full_table.html.erb"
    template "mobile_list.html.erb", "app/views/#{model_name_plural}/_mobile_list.html.erb"
    template "form.html.erb", "app/views/#{model_name_plural}/_form.html.erb"
    template "new.html.erb", "app/views/#{model_name_plural}/new.html.erb"
    template "edit.html.erb", "app/views/#{model_name_plural}/edit.html.erb"
    template "show.html.erb", "app/views/#{model_name_plural}/show.html.erb"
  end

  def add_nav_link
    nav_partial_path = "app/views/layouts/_nav_header.html.erb"

    new_link = "\n      <%= link_to \"#{@model_name_plural.titleize}\", #{@model_name_plural}_path, class: \"p-2 rounded-md text-black font-medium hover:bg-slate-100\" %>"

    gsub_file nav_partial_path,
      /(id="list-links"[^>]*>.*?)(\s*<\/div>)/m,
      "\\1#{new_link}\\2"
  end

  def generate_seed_data(count = 10)
    seed_content = generate_seed_block(@model_name, @json_config["columns"], count)

    # Append to seeds.rb
    seeds_path = "db/seeds.rb"
    append_to_file seeds_path, seed_content
  end

  private

  def generate_seed_block(model_name, columns, count)
    content = "\n# #{model_name} seeds\n"
    content += "puts 'Creating #{model_name.pluralize}...'\n"
    content += "#{count}.times do\n"
    content += "  #{model_name}.create!(\n"

    # Generate attributes for each column
    attributes = columns.map { |col| generate_attribute_line(col) }.compact
    content += attributes.join(",\n")

    content += "\n  )\nend\n"
    content += "puts \"Created \#{#{model_name}.count} #{model_name.pluralize.downcase}\"\n\n"

    content
  end

  def generate_attribute_line(column)
    name = column["name"]
    type = column["type"]

    # Skip timestamp columns as they're handled automatically
    return nil if %w[created_at updated_at].include?(name)

    faker_value = generate_faker_value(name, type)
    return nil unless faker_value

    "    #{name}: #{faker_value}"
  end

  def generate_faker_value(name, type)
    case type
    when "string"
      generate_string_faker(name)
    when "text"
      generate_text_faker(name)
    when "integer"
      generate_integer_faker(name)
    when "decimal", "float"
      generate_decimal_faker(name)
    when "boolean"
      "Faker::Boolean.boolean"
    when "date"
      "Faker::Date.between(from: 1.year.ago, to: Date.current)"
    when "datetime"
      "Faker::Time.between(from: 1.year.ago, to: Time.current)"
    when "reference"
      generate_reference_faker(name)
    end
  end

  def generate_string_faker(name)
    case name.downcase
    when "email"
      "Faker::Internet.email"
    when "first_name", "firstname"
      "Faker::Name.first_name"
    when "last_name", "lastname"
      "Faker::Name.last_name"
    when "name"
      "Faker::Name.name"
    when "phone", "phone_number"
      "Faker::PhoneNumber.phone_number"
    when "address"
      "Faker::Address.full_address"
    when "city"
      "Faker::Address.city"
    when "state"
      "Faker::Address.state"
    when "zip", "zip_code", "postal_code"
      "Faker::Address.zip_code"
    when "country"
      "Faker::Address.country"
    when "company"
      "Faker::Company.name"
    when "title", "job_title"
      "Faker::Job.title"
    when "department"
      "Faker::Commerce.department"
    when "product_name"
      "Faker::Commerce.product_name"
    when "color"
      "Faker::Color.color_name"
    when "url", "website"
      "Faker::Internet.url"
    when "username"
      "Faker::Internet.username"
    when "password"
      "Faker::Internet.password"
    when /description/
      "Faker::Lorem.paragraph"
    when /note/
      "Faker::Lorem.sentence"
    when /code/
      "Faker::Alphanumeric.alphanumeric(number: 8).upcase"
    when /number/
      "Faker::Number.number(digits: 6).to_s"
    else
      "Faker::Lorem.word"
    end
  end

  def generate_text_faker(name)
    case name.downcase
    when /description/
      "Faker::Lorem.paragraph(sentence_count: 3)"
    when /bio/
      "Faker::Lorem.paragraph(sentence_count: 2)"
    when /content/
      "Faker::Lorem.paragraphs(number: 2).join('\\n')"
    when /comment/
      "Faker::Lorem.sentence"
    else
      "Faker::Lorem.paragraph"
    end
  end

  def generate_integer_faker(name)
    case name.downcase
    when /age/
      "Faker::Number.between(from: 18, to: 80)"
    when /price/, /cost/, /amount/
      "Faker::Number.between(from: 10, to: 1000)"
    when /quantity/, /count/
      "Faker::Number.between(from: 1, to: 100)"
    when /year/
      "Faker::Number.between(from: 2020, to: Date.current.year)"
    when /rating/
      "Faker::Number.between(from: 1, to: 5)"
    when /number/
      "Faker::Number.number(digits: 6)"
    else
      "Faker::Number.between(from: 1, to: 1000)"
    end
  end

  def generate_decimal_faker(name)
    case name.downcase
    when /price/, /cost/, /amount/
      "Faker::Commerce.price(range: 10.0..1000.0)"
    when /rating/
      "Faker::Number.decimal(l_digits: 1, r_digits: 1)"
    when /percentage/
      "Faker::Number.decimal(l_digits: 2, r_digits: 2)"
    else
      "Faker::Number.decimal(l_digits: 3, r_digits: 2)"
    end
  end

  def generate_reference_faker(name)
    # Convert reference name to model name
    model_name = name.singularize.camelize
    "#{model_name}.all.sample"
  end
end
