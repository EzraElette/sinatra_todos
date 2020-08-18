class SessionPersistence
  def initialize(session)
    @session = session
    @session[:lists] ||= []
  end

  def find_list(id)
    @session[:lists].find{ |list| list[:id] == id }
  end

  def all_lists
    @session[:lists]
  end

  def add_list(list_name)
    id = next_element_id(all_lists)
    @session[:lists] << { id: id, name: list_name, todos: [] }
  end

  def error?
    @session[:error]
  end

  def error=(message)
    @session[:error] = message
  end

  def display_error
    @session.delete(:error)
  end

  def success?
    @session[:sucess]
  end

  def success=(message)
    @session[:success] = message
  end

  def display_success
    @session.delete(:success)
  end

  def delete_list(id)
    all_lists.reject! { |list| list[:id] == id }
  end

  def update_list_name(id, list_name)
    list = find_list(id)
    list[:name] = list_name
  end

  def add_todo(list_id, name)
    list = find_list(list_id)

    todo_id = next_element_id(list[:todos])
    list[:todos] << { id: todo_id, name: name, completed: false }
  end

  def update_todo_status(list_id, todo_id, status)
    list = find_list(list_id)
    todo = list[:todos].find { |todo| todo[:id] == todo_id }
    todo[:completed] = status
  end

  def delete_todo(list_id, todo_id)
    list = find_list(list_id)
    list[:todos].reject! { |todo| todo[:id] == todo_id }
  end

  def complete_todos(list_id)
    list = find_list(list_id)

    list[:todos].each do |todo|
    todo[:completed] = true
  end
  end

  private

  def next_element_id(elements)
    max = elements.map { |todo| todo[:id] }.max || 0
    max + 1
  end
end
