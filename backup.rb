require 'date'

class Backup
  HOURLY_PERIOD = 'hourly'
  DAILY_PERIOD = 'daily'
  MONTHLY_PERIOD = 'monthly'

  def initialize( source_path, target_path, logger )
    @source_path = source_path
    @target_path = target_path
    @logger = logger
  end

  def snapshot!( source_path, target_path )
    if Dir["#{@source_path}/*"].empty?
      @logger.warn( "Directory #{@source_path} empty. Nothing to backup." )
      return
    end

    cmd( "rm -rf #{target_path}" ) if Dir.exists?( target_path )
    cmd( "cp -al #{source_path} #{target_path}" ) if source_path && Dir.exists?( source_path )
    cmd( "rsync -a -H --delete --numeric-ids #{@source_path}/* #{target_path}" )
  end

  def hourly_snapshot!
    target_path = "#{@target_path}/#{HOURLY_PERIOD}.#{ENV['HOUR'] || DateTime.now.hour}"
    snapshot!( last_snapshot_path(), target_path )
  end

  def daily_snapshot!
    target_path = "#{@target_path}/#{DAILY_PERIOD}.#{ENV['DAY'] || DateTime.now.day}"
    snapshot!( last_snapshot_path(), target_path )
  end

  def monthly_snapshot!
    target_path = "#{@target_path}/#{MONTHLY_PERIOD}.#{ENV['MONTH'] || DateTime.now.month}"
    snapshot!( last_snapshot_path(), target_path )
  end

  private

  def cmd( command )
    @logger.debug( command )
    `#{command}`
  end

  def last_snapshot_path
    return Dir["#{@target_path}/*"].max_by {|directory| File.mtime( directory )}
  end
end
