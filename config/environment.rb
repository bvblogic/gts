# Load the Rails application.
require File.expand_path('../application', __FILE__)

# Initialize the Rails application.
Rails.application.initialize!

ActionView::Base.field_error_proc = Proc.new do |html_tag, instance_tag|
  "<div class='error_field'>#{html_tag}<span class='error_text'>#{instance_tag.error_message.first}</span></div>".html_safe
end