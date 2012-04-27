Sequel.migration do
  up do
    add_column(:pads, :created_at, String)
  end
  down do
    drop_column(:pads, :created_at)
  end
end