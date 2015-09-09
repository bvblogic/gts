namespace :role do
  task :admin, [:user] => :environment do |t, args|
    future_admin = User.find_by_name(args[:user])
    if future_admin.present?
      future_admin.update_column(:role, 1)
      puts "#{future_admin.name} is now admin!"
    else
      new_admin = User.create(name: args[:user],
                              email: "#{args[:user]}@bvblogic.com",
                              role: 1,
                              password: 'hardcode',
                              password_confirmation: 'hardcode')
      new_admin.persisted? ? puts("#{new_admin.name} was successfully created as admin") : puts("#{new_admin.errors.full_messages}")
    end
  end
  task :user, [:user] => :environment do |t, args|
    future_user = User.find_by_name(args[:user])
    if future_user.present?
      future_user.update_column(:role, 0) 
      puts "#{future_user.name} is now user!"
    else
      puts "No such user!"
    end
  end
end

namespace :auth_type do
  @user_file_path = "app/models/user.rb"
  @app_controller_file_path = "app/controllers/application_controller.rb"
  
  task :ldap do
    user_file = File.read(@user_file_path)
    user_replace = user_file.gsub("database_authenticatable", "ldap_authenticatable")
    user_replace = user_replace.gsub("# before_validation :get_ldap_email, :set_role, on: :create",
                                   "before_validation :get_ldap_email, :set_role, on: :create")
    File.open(@user_file_path, "w") {|file| file.puts user_replace}

    app_controller_file = File.read(@app_controller_file_path)
    unless app_controller_file.include?("# before_action :check_auth")
      controller_replace = app_controller_file.gsub("before_action :check_auth", "# before_action :check_auth")
      File.open(@app_controller_file_path, "w") {|file| file.puts controller_replace}
    end
  end

  task :basic do
    user_file = File.read(@user_file_path)
    user_replace = user_file.gsub("ldap_authenticatable", "database_authenticatable")
    unless user_replace.include?("# before_validation :get_ldap_email, :set_role, on: :create")
      user_replace = user_replace.gsub("before_validation :get_ldap_email, :set_role, on: :create",
                                     "# before_validation :get_ldap_email, :set_role, on: :create")
    end
    File.open(@user_file_path, "w") {|file| file.puts user_replace}

    app_controller_file = File.read(@app_controller_file_path)
    controller_replace = app_controller_file.gsub("# before_action :check_auth", "before_action :check_auth")
    File.open(@app_controller_file_path, "w") {|file| file.puts controller_replace}
  end
end
