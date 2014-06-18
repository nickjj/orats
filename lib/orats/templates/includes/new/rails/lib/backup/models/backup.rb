Model.new(:backup, 'Backup for the current RAILS_ENV') do
  split_into_chunks_of 10
  compress_with Gzip

  database PostgreSQL do |db|
    db.sudo_user          = ENV['DATABASE_USERNAME']
    # To dump all databases, set `db.name = :all` (or leave blank)
    db.name               = ENV['DATABASE_NAME']
    db.username           = ENV['DATABASE_USERNAME']
    db.password           = ENV['DATABASE_PASSWORD']
    db.host               = ENV['DATABASE_HOST']
    db.port               = 5432
    db.socket             = '/var/run/postgresql'
    #db.skip_tables        = ['skip', 'these', 'tables']
    #db.only_tables        = ['only', 'these', 'tables']
  end

  # uncomment the block below to archive a specific path
  # this may be useful if you have user supplied content

  # archive :app_archive do |archive|
  #   archive.add File.join(ENV['PROJECT_PATH'], 'public', 'system')
  # end

  # uncomment the block below and fill in the required information
  # to use S3 to store your backups

  # don't want to use S3? check out the other available options:
  # http://meskyanichi.github.io/backup/v4/storages/

  # store_with S3 do |s3|
  #   s3.access_key_id = ENV['S3_ACCESS_KEY_ID']
  #   s3.secret_access_key = ENV['S3_SECRET_ACCESS_KEY']
  #   s3.region = ENV['S3_REGION']
  #   s3.bucket = 'backup'
  #   s3.path = "/database/#{ENV['RAILS_ENV']}"
  # end

  ENV['SMTP_ENCRYPTION'].empty? ? mail_encryption = 'none' : mail_encryption = ENV['SMTP_ENCRYPTION']

  notify_by Mail do |mail|
    mail.on_success           = false
    #mail.on_warning           = true
    mail.on_failure           = true
    mail.from                 = ENV['ACTION_MAILER_DEFAULT_FROM']
    mail.to                   = ENV['ACTION_MAILER_DEFAULT_TO']
    mail.address              = ENV['SMTP_ADDRESS']
    mail.port                 = ENV['SMTP_PORT'].to_i
    mail.domain               = ENV['SMTP_DOMAIN']
    mail.user_name            = ENV['SMTP_USERNAME']
    mail.password             = ENV['SMTP_PASSWORD']
    mail.authentication       = ENV['SMTP_AUTH']
    mail.encryption           = mail_encryption.to_sym
  end
end