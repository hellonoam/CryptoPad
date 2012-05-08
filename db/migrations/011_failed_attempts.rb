Sequel.migration do
  up do
    create_table(:failed_attempts) do
      primary_key :id
      foreign_key :pad_id, :pads, :key => :id
      Integer :count, :default => 0, :null => false
      String :last_try_at
    end
  end
  down do
    drop_table(:failed_attempts)
  end
end