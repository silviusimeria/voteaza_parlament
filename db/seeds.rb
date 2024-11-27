# db/seeds.rb
if ENV['ADMIN_EMAIL'].present? && ENV['ADMIN_PASSWORD'].present?
  if AdminUser.count.zero?
    AdminUser.create!(
      email: ENV['ADMIN_EMAIL'],
      password: ENV['ADMIN_PASSWORD'],
      password_confirmation: ENV['ADMIN_PASSWORD']
    )
    puts 'Admin user created'
  end
else
  puts 'Skipping admin user creation - missing ENV variables'
end
