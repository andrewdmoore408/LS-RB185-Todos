require "pg"

class DatabasePersistence
  def initialize(logger)
    @db = if Sinatra::Base.production?
            PG.connect(ENV['DATABASE_URL'])
          else
            PG.connect(dbname: "todos")
          end
    @logger = logger
  end

  def query(statement, *params)
    @logger.info "#{statement}: #{params}"

    @db.exec_params(statement, params)
  end

  def disconnect
    @db.close
  end

  def change_list_name(list_id, new_name)
    sql = "UPDATE lists SET name = $1 WHERE id = $2"
    query(sql, new_name, list_id)
    # list = get_list(list_id)
    # list[:name] = new_name
  end

  def complete_list(list_id)
    sql = "UPDATE todos SET completed = true WHERE list_id = $1"
    query(sql, list_id)
  end

  def create_new_list(list_name)
    sql = "INSERT INTO lists (name) VALUES ($1);"
    query(sql, list_name)
  end

  def create_new_todo(list_id, todo_text)
    sql = "INSERT INTO todos (list_id, name) VALUES ($1, $2);"
    query(sql, list_id, todo_text)
  end

  def delete_list(id)
    sql = "DELETE FROM lists WHERE id = $1;"
    query(sql, id)
  end

  def delete_todo(list_id, todo_id)
    sql = "DELETE FROM todos WHERE list_id = $1 AND id = $2;"
    query(sql, list_id, todo_id)
  end

  def get_list(id)
    sql = <<~SQL
          SELECT lists.*,
           COUNT(todos.id) AS todos_count,
           COUNT(NULLIF(todos.completed, true)) AS todos_remaining_count
           FROM lists
           LEFT JOIN todos ON todos.list_id = lists.id
           WHERE lists.id = $1
           GROUP BY lists.id
           ORDER BY lists.name;
          SQL

    list_result = query(sql, id)

    record_to_list_hash(list_result.first)
  end

  def list_name_taken?(list_name)
    # lists.any? { |list| list[:name] == list_name }
  end

  def lists
    # optimized query
    sql = <<~SQL
          SELECT lists.*,
           COUNT(todos.id) AS todos_count,
           COUNT(NULLIF(todos.completed, true)) AS todos_remaining_count
           FROM lists
           LEFT JOIN todos ON todos.list_id = lists.id
           GROUP BY lists.id
           ORDER BY lists.name;
          SQL

    lists_result = query(sql)

    lists_result.map do |record|
      record_to_list_hash(record)
    end
  end

  def error=(error_msg)
    # @session[:error] = error_msg
  end

  def success=(success_msg)
    # @session[:success] = success_msg
  end

  def update_todo(list_id, todo_id, is_completed)
    sql = "UPDATE todos SET completed = $1 WHERE list_id = $2 AND id = $3;"
    query(sql, is_completed, list_id, todo_id)
  end

  def find_todos_for_list(list_id)
    todos_sql = "SELECT * FROM todos WHERE list_id = $1"
    todos_result = query(todos_sql, list_id)

    todos_result.map do |todo_row|
        { id: todo_row["id"].to_i,
          name: todo_row["name"],
          completed: todo_row["completed"] == 't' }
    end
  end

  private

  def record_to_list_hash(record)
    { id: record["id"].to_i,
    name: record["name"],
    todos_count: record["todos_count"].to_i,
    todos_remaining_count: record["todos_remaining_count"].to_i }
  end
end
