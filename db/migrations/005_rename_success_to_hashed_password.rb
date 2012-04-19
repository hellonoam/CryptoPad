Sequel.migration do
  up do
    alter_table(:pads) do
      rename_column(:success, :hashed_password)
    end
  end
  down do
    alter_table(:pads) do
      rename_column(:hashed_password, :success)
    end
  end
end