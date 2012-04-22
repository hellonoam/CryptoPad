Sequel.migration do
  up do
    create_table(:pad_files) do
      primary_key :id
      foreign_key :pad_id, :pads, :key => :id
      String :filename, :null => false
    end
  end
  down do
    drop_table(:pad_files)
  end
end