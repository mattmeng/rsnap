require 'date'

class Backup
  HOURLY_PERIOD = 'hourly'
  DAILY_PERIOD = 'daily'
  WEEKLY_PERIOD = 'weekly'
  MONTHLY_PERIOD = 'monthly'

  def initialize( source_path, target_path, logger )
    @source_path = source_path
    @target_path = target_path
    @logger = logger
  end

  def snapshot!( snapshots, period, limit )
    if Dir["#{@source_path}/*"].empty?
      raise "Directory #{@source_path} empty. Nothing to backup."
    end

    snapshots = snapshots.reverse
    snapshots.each_with_index do |snapshot_path, index|
      n = snapshots.count + 1 - index
      target_path = "#{File.dirname( snapshot_path )}/#{period}.#{sprintf( '%02d', n)}"
      if n >= limit
        cmd( "rm -rf #{snapshot_path}" )
      elsif n == 2
        cmd( "cp -al #{snapshot_path} #{target_path}" )
      else
        cmd( "mv #{snapshot_path} #{target_path}" )
      end
    end

    cmd( "rsync -a -H --delete --numeric-ids #{@source_path}/* #{@target_path}/#{period}.01" )
  end

  def hourly_snapshot!
    snapshot!( hourly_snapshots(), HOURLY_PERIOD, 24 )
  end

  def daily_snapshot!
    snapshot!( daily_snapshots(), DAILY_PERIOD, 7 )
  end

  private

  def cmd( command )
    @logger.debug( command )
    `#{command}`
  end

  def snapshots( period )
    return Dir["#{@target_path}/#{period}.*"]
      .select {|dir| Dir.exists?( dir )}
      .sort_by {|dir| dir}
  end

  def hourly_snapshots
    return snapshots( HOURLY_PERIOD )
  end

  def daily_snapshots
    return snapshots( DAILY_PERIOD )
  end

  def weekly_snapshots
    return snapshots( WEEKLY_PERIOD )
  end

  def monthly_snapshots
    return snapshots( MONTHLY_PERIOD )
  end
end
