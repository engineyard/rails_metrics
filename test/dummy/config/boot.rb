require File.expand_path("../../../../rails/.bundle/environment", File.dirname(__FILE__))
require 'rails/all'

$:.unshift File.expand_path('../../../../lib', __FILE__)
require 'rails_metrics'

# To pick the frameworks you want, remove 'require "rails/all"'
# and list the framework railties that you want:
#
# require "active_model/railtie"
# require "active_record/railtie"
# require "action_controller/railtie"
# require "action_view/railtie"
# require "action_mailer/railtie"
# require "active_resource/railtie"