class BackupDatabaseJob < ApplicationJob
  queue_as :default

  RETENTION = 14

  def perform
    backup_dir = Rails.root.join("backups")
    FileUtils.mkdir_p(backup_dir)
    destination = backup_dir.join("solar-#{Time.current.strftime('%Y%m%d-%H%M%S')}.sqlite3")
    quoted = ActiveRecord::Base.connection.quote(destination.to_s)
    ActiveRecord::Base.connection.execute("VACUUM INTO #{quoted}")
    Dir.glob(backup_dir.join("solar-*.sqlite3")).sort.reverse.drop(RETENTION).each { |file| File.delete(file) }
  end
end
