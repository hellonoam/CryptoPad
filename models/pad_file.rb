
class PadFile < Sequel::Model

  many_to_one :pad

  def before_destroy
    # add error handling - if file doesn't exist don't throw an error but if delete failed throw error.
    File.delete "#{Dir.pwd}/file_transfers/#{self.pad.hash_id}/#{self.filename}"
  end

end
