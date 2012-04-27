Sequel.migration do
  up do
    create_table(:pad_security_options) do
      primary_key :id
      foreign_key :pad_id, :pads, :key => :id
      String :die_time, :null => false
      Boolean :allow_reader_to_destroy, :default => false
      Boolean :destroy_after_multiple_failed_attempts, :default => true
      Boolean :no_password, :default => false
    end
  end
  down do
    drop_table(:pad_security_options)
  end
end