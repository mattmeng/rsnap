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
    cmd( "rsync -aH --delete --numeric-ids #{@source_path}/ #{target_path}" )
    cmd( "touch #{target_path}" )
  end

  def hourly_snapshot!
    hour = ENV['HOUR'] || DateTime.now.hour
    hourly_cleanup( hour )
    target_path = "#{@target_path}/#{HOURLY_PERIOD}.#{hour}"
    snapshot!( last_snapshot_path(), target_path )
  end

  def daily_snapshot!
    day = ENV['DAY'] || DateTime.now.day
    daily_cleanup( day )
    target_path = "#{@target_path}/#{DAILY_PERIOD}.#{day}"
    snapshot!( last_snapshot_path(), target_path )
  end

  def monthly_snapshot!
    month = ENV['MONTH'] || DateTime.now.month
    monthly_cleanup( month )
    target_path = "#{@target_path}/#{MONTHLY_PERIOD}.#{month}"
    snapshot!( last_snapshot_path(), target_path )
  end

  def cleanup( period, index, limit )
    Dir["#{@target_path}\/#{period}.*"].each do |path|
      unless ((index - limit + 1)...index) === path[/#{period}.(\d+)/, 1].to_i
        cmd( "rm -rf #{path}" )
      end
    end
  end

  def hourly_cleanup( hour )
    cleanup( HOURLY_PERIOD, hour, 8 )
  end

  def daily_cleanup( day )
    cleanup( DAILY_PERIOD, day, 7 )
  end

  def monthly_cleanup( month )
    cleanup( MONTHLY_PERIOD, month, 6 )
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
