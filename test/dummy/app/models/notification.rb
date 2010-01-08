class Notification < ActionMailer::Base
  def welcome
    subject "Welcome"
    from "sender@rails-metrics-app.com"
    recipients "destination@rails-metrics-app.com"
  end
end
