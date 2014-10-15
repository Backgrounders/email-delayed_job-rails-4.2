require 'rails_helper'

describe ContactMailer do
  before(:each) do
    @email = ContactMailer.contact(
    'John Travolta',
    'travolta@email.com',
    'Awesome site! I love that this uses a background job.'
    )
  end

  it 'should have a reply email' do
    expect(@email).to deliver_from 'example@email.com'
  end

  it 'should have a subject' do
    expect(@email).to have_subject 'New message from John Travolta'
  end

  it 'should have a body' do
    expect(@email).to have_body_text 'Awesome site! I love that this uses a background job.'
  end
end
