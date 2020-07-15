require 'sinatra'
require 'sinatra/reloader' if development?
require 'sinatra/content_for'
require 'tilt/erubis'

configure do
  enable :sessions
  set :session_secret, 'secret'
  set :erb, :escape_html => true
end

# Return an error message if the name is invalid. Return nil if the name is valid.
def error_for_list_name(list_name)
  list_name.strip!
  if !(1..100).cover? list_name.size
    'List name must be between 1 and 100 characters.'
  elsif session[:lists].any? { |list| list[:name] == list_name }
    'List name must be unique.'
  end
end

# Return an error message if the name is invalid. Return nil if the name is valid.
def error_for_todo(name)
  name.strip!
  'Todo must be between 1 and 100 characters.' if !(1..100).cover? name.size
end

# load a list or set an error message and return to home page
def load_list(index)
  list = session[:lists].find { |list| list[:id] == index }
  return list if list

  session[:error] = "The specified list was not found."
  redirect '/lists'
end

helpers do
  # return a boolean based on wether or not a list as at least one todo and all toodos are completed
  def list_complete?(list)
    todos_count(list) > 0 && todos_remaining_count(list) == 0
  end

  def todo_complete?(todo)
    "complete" if todo[:completed]
  end

  # return a string based on what class a string falls into or nil
  def list_class(list)
    "complete" if list_complete?(list)
  end

  # calculate remaining number of todos for a given list
  def todos_remaining_count(list)
    list[:todos].select { |todo| todo[:completed] == false }.count
  end

  # calculate number of todos in a given list
  def todos_count(list)
    list[:todos].count
  end

  # sorts lists by completion
  def sort_lists(lists, &block)
    complete_lists, incomplete_lists = lists.partition { |list| list_complete?(list) }

    complete_lists.each { |list| yield list, lists.index(list) }
    incomplete_lists.each { |list| yield list, lists.index(list) }
  end

  # sort todos by completion
  def sort_todos(todos, &block)
    complete_todos, incomplete_todos = todos.partition { |todo| todo[:completed] }

    incomplete_todos.each { |todo| yield todo, todos.index(todo) }
    complete_todos.each { |todo| yield todo, todos.index(todo) }

  end

  def next_element_id(elements)
    max = elements.map { |element| element[:id] }.max || 0
    max + 1
  end
end

before do
  session[:lists] ||= []
end

get '/' do
  redirect '/lists'
end

# view all the lists
get '/lists' do
  @lists = session[:lists]
  erb :lists, layout: :layout
end

# Create an new list
post '/lists' do
  error = error_for_list_name(params[:list_name])
  if error
    session[:error] = error
    erb :new_list, layout: :layout
  else
    id = next_element_id(session[:lists])
    session[:lists] << { id: id, name: params[:list_name], todos: [] }
    session[:success] = 'The list has been created.'
    redirect '/lists'
  end
end

# Render the new list form
get '/lists/new' do
  erb :new_list, layout: :layout
end

# view a single list
get '/lists/:index' do
  @index = params[:index].to_i
  @list = load_list(@index)

  erb :list, layout: :layout
end

# Edit a list
get '/lists/:index/edit' do
  @index = params[:index].to_i
  @list = load_list(@index)
  erb :edit_list, layout: :layout
end

# save the changes for a list edit
post '/lists/:index' do
  @list_name = params[:list_name]
  error = error_for_list_name(@list_name)
  @index = params[:index].to_i

  if error
    session[:error] = error
    erb :edit_list, layout: :layout
  else
    session[:lists][@index][:name] = @list_name
    session[:success] = "List has been updated."
    redirect "/lists/#{ @index }"
  end
end

# delete a list
post '/lists/:index/destroy' do

  session[:lists].reject! { |list| list[:id] == params[:index].to_i }
  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    "/lists"
  else
    session[:success] = "The list has been removed."
    redirect '/lists'
  end
end

# add a new todo to a list
post '/lists/:index/todos' do

  text = params[:todo]
  error = error_for_todo(text)
  @index = params[:index].to_i
  @list = load_list(@index)
  if error
    session[:error] = error
    erb :list, layout: :layout
  else

    id = next_element_id(@list[:todos])
    @list[:todos] << { id: id, name: text, completed: false }

    session[:success] = "The todo was added."
    redirect "/lists/#{ @index }"
  end
end

# delete a todo from a list
post '/lists/:index/todos/:todo/destroy' do
  @list = load_list(params[:index].to_i)
  @list[:todos].reject! { |todo| todo[:id] == params[:todo].to_i }

  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    status 204
  else
    session[:success] = "Todo has been deleted."
    redirect "/lists/#{ params[:index] }"
  end
end

# mark a todo complete or incomplete
post '/lists/:index/todos/:todo' do
  @index = params[:index].to_i
  @list = load_list(@index)
  todo_id = params[:todo].to_i

  is_completed = params[:completed] == "true"
  todo = @list[:todos].find { |todo| todo[:id] == todo_id }
  todo[:completed] = is_completed
  session[:success] = "The todo has been updated"
  redirect "/lists/#{ @index }"
end

# mark all todos completed
post '/lists/:index/complete_all' do
  @index = params[:index].to_i
  @list = load_list(@index)
  @list[:todos].each do |todo|
    todo[:completed] = true
  end

  session[:success] = "All todos have been completed."
  redirect "/lists/#{ @index }"
end