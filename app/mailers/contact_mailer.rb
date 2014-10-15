class ContactMailer < ActionMailer::Base
  default from: 'example@email.com'

  def contact(name, email, body)
    @name = name
    @email = email
    @body = body
    mail(to: ENV['GMAIL_SEND_TO'], subject: "New message from #{@name}")
  end
end
