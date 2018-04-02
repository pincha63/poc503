helpers do
  def css(*stylesheets)
    stylesheets.map do |myStylesheet|
      "<link href=\"/#{myStylesheet}.css\"
      media=\"screen, projection\" rel=\"stylesheet\" />"
    end.join
  end
end
get ('/styles.css'){scss :styles}

require 'sequel'
  DB = Sequel.connect("postgres://postgres:gondilan90@localhost:5432/dev01")
  dcards = DB[:cards]
  dboards = DB[:boards]
