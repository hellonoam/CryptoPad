# TODO: change table name, like this:
# class FailedAttempts < Sequel::Model(:failed_attempts)
class FailedAttempt < Sequel::Model

  ATTEMPTS_ALLOWED = 4
  ATTEMPTS_ALLOWED_UNTIL_DESTROY = 40
  WAIT_TIME = 60 # 1 mins

  many_to_one :pad

  def initialize(params)
    super(params)
  end

  def allow_attempt?
    return true unless (self.count + 1) % (ATTEMPTS_ALLOWED + 1) == 0
    self.last_try_at <= (Time.now - WAIT_TIME).to_s
  end

  def increment_tries
    self.count = self.count + 1
    if self.count >= ATTEMPTS_ALLOWED_UNTIL_DESTROY &&
       self.pad.pad_security_option.destroy_after_multiple_failed_attempts
      return self.pad.destroy
    end
    self.last_try_at = Time.now
    self.save
  end

end
