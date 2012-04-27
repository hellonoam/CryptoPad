class PadSecurityOption < Sequel::Model

  many_to_one :pad

  def initialize(params)
    # Converting hash to be of the form: sym => val with underscores rathen than camel case
    params.keys.each { |k| params[k.to_s.gsub(/(.)([A-Z])/,'\1_\2').downcase.to_sym] = params.delete(k) }

    # For now setting die time to a year from now if never destroy was selected.
    params[:destroy_after_days] = 365 if params[:never_destroy]

    # Whitelisting certain fields.
    params.select! do |k, v|
      [:pad_id, :destroy_after_days, :destroy_after_multiple_failed_attempts, :no_password,
       :allow_reader_to_destroy].index(k)
    end

    super(params)
  end

  def validate
    super
    # TODO: add validations
  end

end
