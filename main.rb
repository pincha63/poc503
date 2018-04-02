# This is POC503
# Sinatra and Sequel, CRUD, no ORM
# and Ajax

require 'sinatra'
require 'sinatra/reloader' if development?
require 'slim'
require 'sass'

require './myinit.rb' # stylesheet stuff and DB connect
  dcards = DB[:cards]
  dboards = DB[:boards]

get ('/') do     # router 01
  @cards = dcards.all  # if there are comments, get them as well
  slim :board  # <------------ yield to slim 01   :board
end

get '/cards' do #show list of cards     # router 02
  @cards = dcards.all  # if there are comments, get them as well
  slim :cards  # <------------ yield to slim 02   :cards
end

# This starts creation of new record (works!)
get '/cards/new' do           # router 03
  @card = { :kid => 0, :bid => 0, :kname=>"", :kcontents=>"" }    # was Card.new 
  slim :card_new  # <------------ yield to slim 03   :card_new
  # technical debt: allow canceling the new card creation
end

# This completes the creation of new record (called by the form) (works!)
post '/finalize_add' do      # router 04
  x1 = (params[:card])
  # using "returning" returns an array of hashes... 
  # calling "first" gets one hash, then call [:kid] to reference the primary key
  new_kid = dcards.insert(:bid => x1["bid"], :kseq => 1, :kname=>x1["kname"], \
      :kcontents=>x1["kcontents"], :kstatus =>1, \
      :kcreatedTS => Time.now.utc, :kmodifiedTS => Time.now.utc)
  puts "Created card with name: #{x1["kname"]} and ID: #{new_kid}"
  redirect to ("/")   # <<<<<<<<<<<<<<<<<<<<<------ redirect  1
end

get '/cards/:id/edit' do      # router 05
  puts "Start Editing Routine"
  @card = dcards.first(kid: params[:id])
  puts @card.inspect
  slim :card_edit  # <------------ yield to slim 04   :card_edit
end

get '/cards/:id' do      # router 06
  puts "Show card #{params[:id]}"
  @card = dcards.first(kid: params[:id])  #was Card.first(kid: params[:id])
  slim :card_show  # <------------ yield to slim 05   :card_show
end

get '/getHtml/:id' do               # AJAX ROUTER 101: writes the HTML for displaying a record
  puts "Being Called #{params[:id]}"
  myCard = dcards.first(kid: params[:id])
  "<p>Card IDs is: #{myCard[:kid]}<br>Parent board ID is: #{myCard[:bid]}<br>Card name is: #{myCard[:kname]}<br>" + \
  "Content is: #{myCard[:kcontents]}<br>Sequence is: #{myCard[:kseq]}<br>Status is: #{myCard[:kstatus]}<br>" + \
  "Created timestamp is: #{myCard[:kcreatedTS]}<br>Modified timestamp is: #{myCard[:kmodifiedTS]}"
end

get '/getHtmlForm/:id' do               # AJAX ROUTER 102: writes the HTML form for editing
  puts "Form Being Called #{params[:id]}"
  myCard = dcards.first(kid: params[:id])
  puts "MyCard.bid = #{myCard[:bid]}"
  puts "MyCard.content = #{myCard[:kcontents]}"
  puts "MyCard.name = #{myCard[:kname]}"
  ajax_result = "<form id=\"myForm\"  method=\"POST\" action=\"/ajaxcards/#{myCard[:kid]}\"> <input type=\"hidden\" name=\"_method\" value=\"PUT\">"
  ajax_result += "<label for=\"kname\">Name</label><input id=\"Name\" name=\"kname\" type=\"text\" value=\"#{myCard[:kname]}\" />"
  ajax_result += '<label for="bid">Board ID</label><input id="bid" name="bid" type="number" value=' 
  ajax_result += "\"#{myCard[:bid]}\" />"
  ajax_result += '<label for="contents">Contents</label><input id="kcontents" name="kcontents" type="text" value=' 
  ajax_result += "\"#{myCard[:kcontents]}\" />"
  ajax_result += "<p><input id=\"savecard\" type=\"submit\" value=\"Save Card\" /></p>   </form>"
    puts ajax_result
  ajax_result += "<br><br><br><br><form id=\"myForm\"  method=\"POST\" action=\"/ajaxcards/#{myCard[:kid]}\">"
  ajax_result += "<input type=\"hidden\" name=\"_method\" value=\"DELETE\">"
  ajax_result += "<p><input id=\"deletecard\" type=\"submit\" value=\"Delete Card\" /></p> </form>"
    puts ajax_result
  x2  =  ajax_result 
end

# This is a regular PUT route. It updates one record per contents of params[:card]
put '/cards/:id' do      # router 07
  x1 = (params[:card])
  puts "Inspecting returned record (x1)"
  puts x1.inspect
  myKid = params[:id]
  puts "Updated card with ID: #{myKid}  ---------- before"
  puts dcards.where(kid: myKid).first.inspect 
  dcards.where(kid: myKid).update(:bid => x1["bid"], :kseq => 1, :kname=>x1["kname"], \
      :kcontents=>x1["kcontents"], :kstatus =>1, :kmodifiedTS => Time.now.utc)
  puts "Updated card with ID: #{myKid}  ---------- after"
  puts dcards.where(kid: myKid).first.inspect 
  redirect to("/cards/#{myKid}") # <<<<<<<<<<<<<<<<<<<<<------ redirect  2
end

# Regular Delete
delete '/card/:id' do      # router 08
  myKid = params[:id]
  myName = dcards.where(kid: params[:id]).first[:kname]
  puts "---------- Non-Ajax version of: Deleting card with ID: #{params[:id]} and name #{myName}"
  dcards.where(kid: myKid).delete
  redirect to('/') # <<<<<<<<<<<<<<<<<<<<<------ redirect  3
end

# Ajax delete... same as regular
delete '/ajaxcards/:id' do
  myKid = params[:id]
  myName = dcards.where(kid: params[:id]).first[:kname]
  puts "======== AJAX version of: Deleting card with ID: #{params[:id]} and name #{myName}"
  dcards.where(kid: myKid).delete
  redirect to('/') # <<<<<<<<<<<<<<<<<<<<<------ redirect  3
end

# This is an Ajax PUT route. It updates one record per contents of params[:card]
put '/ajaxcards/:id' do      # router 07
  myKid = params[:id]
  puts "Updated card with ID: #{myKid}  ---------- before"
  puts dcards.where(kid: myKid).first.inspect 
  dcards.where(kid: myKid).update(:bid => params[:bid], :kseq => 1, :kname=>params[:kname], \
      :kcontents=>params[:kcontents], :kstatus =>1, :kmodifiedTS => Time.now.utc)
  puts "Updated card with ID: #{myKid}  ---------- after"
  puts dcards.where(kid: myKid).first.inspect 
  redirect to("/") 
end
