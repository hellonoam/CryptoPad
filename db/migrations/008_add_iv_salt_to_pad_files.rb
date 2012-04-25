Sequel.migration do
  up do
    add_column(:pad_files, :iv, String)
    add_column(:pad_files, :salt, String)
  end
  down do
    drop_column(:pad_files, :iv)
    drop_column(:pad_files, :salt)
  end
end