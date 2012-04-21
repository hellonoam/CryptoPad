Sequel.migration do
  up do
    alter_table(:pads) do
      rename_column(:text, :encrypted_text)
    end
  end
  down do
    alter_table(:pads) do
      rename_column(:encrypted_text, :text)
    end
  end
end