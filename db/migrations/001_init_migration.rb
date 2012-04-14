Sequel.migration do
  up do
    create_table(:pads) do
      primary_key :id
      String :text, :null => false
      String :success, :null => false
      Date :die_time, :null => false
      String :encrypt_method
      String :hash_id, :null => false
      String :salt, :null => false
    end
  end
  down do
    drop_table(:pads)
  end
end