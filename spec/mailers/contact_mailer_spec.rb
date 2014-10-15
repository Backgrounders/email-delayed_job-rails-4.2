require 'rails_helper'

describe ContactMailer do
  include EmailSpec::Helpers
  include EmailSpec::Matchers

  before do
    email = ContactMailer.contact(
    'The Olsen Twins',
    'olsentwins@email.com',
    'Awesome site! We love that this uses a background job.'
    )
  end

  it 'should have a reply email' do
    email.must_have_reply_to 'example@email.com'
  end

  it 'should have a subject' do
    email.must_have_subject 'Thanks for dropping a message!'
  end

  it 'should have a body' do
    email.must_have_body_text "Thanks for contacting us, The Olsen Twins! We'll
    be sure to get back to you soon."
  end
end
