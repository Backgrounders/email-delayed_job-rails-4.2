# Description

This example app shows how to use Action Mailer with Delayed Job using Rails
4.2. We're going to just make a simple contact form for visitors to our site
to send us a message. If you just want to look at the code, go ahead and clone
the repo. Otherwise, if you want to follow along, here's a rundown on how to get
started:

# Installation

```
gem 'rails', '4.2.0.beta2'

# Optional, but useful gems for testing and setting up your ENV variables
gem 'foreman'
gem 'email_spec'
gem 'rspec-rails'
```

Feel free to use any test framework that works for you. I used Rspec. Foreman
is a useful gem for injecting environmental variables using dotenv. Never
store your passwords or keys in a repo!

# Setting up Action Mailer

Email can be thought of as just another template like the ones automatically
called by the controller - in fact, they work just the same way. While Mailers
are called into action by a controller, each action of a Mailer is expected
to have a file of the same name under app/views/MAILER_NAME_mailer and it
injects instance variables to use in the template the same way.

First let's start with some tests:

```
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
end
```

You can add more as needed and with whatever test framework works for you. Once
you have them written, move on to making the mailer.

First, let's make a mailer. You can use the generator if you want or build it
from scratch.

```
class ContactMailer < ActionMailer::Base
  default from: ENV['GMAIL_SENT_FROM']

  def contact(name, email, body)
    @name = name
    @email = email
    @body = body
    mail(to: ENV['GMAIL_SEND_TO'], subject: "New message from #{@name}")
  end
end
```

Obviously, replace the ENV variables with what you want (but keep them as
environmental variables unless you like putting your test emails up on
Github).

The #contact method functions just like a controller method. It sets up
variables for the view, and in this case, it builds up an email with the headers
you want. It'll look for app/views/contact_mailer/contact.html.erb, so let's go
make that.

```
<!DOCTYPE html>
<html>
  <head>
    <meta content='text/html; charset=UTF-8' http-equiv='Content-Type' />
  </head>
  <body>
    <h1>New message</h1>
    <p><%= @name %> says hi - here's their message:</p>
    <p><%= @body %></p>

    <p>Email them back at: <%= @email %></p>
  </body>
</html>
```

Barebones, but it works. Now let's go make a view for the users so they can
fill out a form and send an email to us.

```
<h1>Example Mailer</h1>

<p>Leave us a message!</p>

<%= form_tag contact_path do |f| %>

<%= label_tag :name %> <br>
<%= text_field_tag :name %> <br>

<%= label_tag :email %> <br>
<%= email_field_tag :email %> <br>

<%= label_tag :body %> <br>
<%= text_area_tag :body %> <br>

<%= submit_tag 'Submit' %>

<% end %>
```

Now we simply make a route for post requests to the path listed, and implement
the controller action.

```
# In routes.rb

root 'static_pages#index'
post '/' => 'static_pages#contact', as: 'contact'
```

And in the controller:

```
def contact
  ContactMailer.contact(params[:name], params[:email], params[:body]).deliver_now

  redirect_to root_url
end
```

Note the use of #deliver_now instead of #deliver. As of Rails 4.2, this is
important since it interacts with ActiveJob in determining whether our email
should be sent to a background process with #deliver_later or sent directly
by our web server. We'll change it later, let's just get it working for now.

Alright, we're all ready to go. We've got a working form and our email set up,
so let's fill it out and... no email. That's fine. We just have to set up
ActionMailer to send live emails.

```
ActionMailer::Base.delivery_method = :smtp
ActionMailer::Base.smtp_settings = {
  address: 'smtp.gmail.com',
  enable_starttls_auto: true,
  port: 587,
  authentication: :plain,
  user_name: ENV['GMAIL_USERNAME'],
  password: ENV['GMAIL_PASSWORD']
}
```

Put this code where you like - either inside an initializer for all
environments, or inside your environments files if you want different settings
for different environments. You probably do, but no big deal for making this
app work.

All right. Now you've got a working mailer.

# Setting up a background service

Ouch. Sending just that one email takes a while, doesn't it? It doesn't get much
simpler than this, yet the page still probably took over half a second to
redirect back to the root url. That's a problem. Enter background jobs.

# Delayed Job

There are a number of different services you can use for this, and others such
as Sidekiq and Resque are used in other example apps within this Uploaders
organization. Here, we'll cover how to use a simple one - Delayed Job, and
we'll try to get it hooked up with the new Rails 4.2 feature ActiveJob.

# Installation

```
gem 'delayed_job_active_record'
gem 'daemons'
```

After that, run the generator it provides and migrate

```
rails generate delayed_job:active_record
```

In our static pages controller, let's go ahead and change to deliver_later

```
def contact
  ContactMailer.contact(params[:name], params[:email], params[:body]).deliver_later

  redirect_to root_url
end
```

That gets it set up with ActiveJob, but how do we link ActiveJob with
Delayed_Job? Fortunately, that's exactly the point of ActiveJob. Just change
out the adapter in your config/environments/development.rb.

Add in:

```
config.active_job.queue_adapter = :delayed_job
```

Great. Now if you try to send an email with the form, you'll notice that the
redirect takes place much faster as a Job object is made, serialized, and
stored in the database. But... no email. That's because we don't have a
background service running yet. Let's get that going. Since we already
have our bin/delayed_job from when we ran the generator, we can go ahead and
run

```
RAILS_ENV=development bin/delayed_job start
```

NOTE: If you were using foreman or something similar to store environmental
variables, remember that your background process might need them! If you stored
your gmail username and password as environmental variables (you did, right?)
and failed to make those available, then the worker will take care of the job
without complaining, but the connection will fail and you won't send an email.
To fix this, make sure your environmental variables are still set for this
command. With foreman, you would do this:

```
RAILS_ENV=development foreman run bin/delayed_job start
```

And there we go! This starts a background worker that will complete that job
that was stored in the database and continue to check for new jobs to do every
few seconds. If you go and check using the form again, you'll find that not
only is it a fast reload, but you get your email delivered in a very reasonable
time window. The background process makes everything a great deal easier.

Hopefully you've found this easy to use, and ActiveJob actually makes it all
even easier than before. Make sure to explore your options, since there's loads
of other things that you can do with background jobs to make your apps more
pleasing to interact with.
