Sequel.migration do
  up do
    create_table(:users) do
      primary_key :id
      String :email, :null => false
    end
  end
  down do
    drop_table(:users)
  end
end