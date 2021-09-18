class SessionPersistence
  def initialize(session)
    @session = session
    @session[:lists] ||= []
  end

  def change_list_name(list_id, new_name)
    list = get_list(list_id)
    list[:name] = new_name
  end

  def complete_list(list_id)
    list = get_list(list_id)

    list[:todos].each do |todo|
      todo[:completed] = true
    end
  end

  def create_new_list(list_name)
    id = next_element_id(lists)
    lists << { id: id, name: list_name, todos: [] }
  end

  def create_new_todo(list_id, todo_text)
    list = get_list(list_id)

    id = next_element_id(list[:todos])
    list[:todos] << { id: id, name: todo_text, completed: false }
  end

  def delete_list(id)
    lists.reject! { |list| list[:id] == id }
  end

  def delete_todo(list_id, todo_id)
    list = get_list(list_id)
    list[:todos].reject! { |todo| todo[:id] == todo_id }
  end

  def get_list(id)
    lists.find{ |list| list[:id] == id }
  end

  def list_name_taken?(list_name)
    lists.any? { |list| list[:name] == list_name }
  end

  def lists
    @session[:lists]
  end

  def error=(error_msg)
    @session[:error] = error_msg
  end

  def success=(success_msg)
    @session[:success] = success_msg
  end

  def update_todo(list_id, todo_id, is_completed)
    list = get_list(list_id)

    todo = list[:todos].find { |todo| todo[:id] == todo_id }
    todo[:completed] = is_completed
  end

  private

  def next_element_id(elements)
    max = elements.map { |todo| todo[:id] }.max || 0
    max + 1
  end
end