Sequel.migration do
  up do
    add_column(:pads, :iv, String)
  end
  down do
    drop_column(:pads, :iv)
  end
end