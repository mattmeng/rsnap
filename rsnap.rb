#! /usr/bin/env ruby


require 'yaml'
require 'logger'
require_relative 'backup.rb'

BACKUP_PATH = '/backup'
CONFIG_PATH = "#{BACKUP_PATH}/rsnap.yml"
LOG_PATH = "#{BACKUP_PATH}/rsnap.log"

$logger = Logger.new( LOG_PATH, 'daily', level: Logger::DEBUG )
# $logger.level = Logger::WARN

def quit( exit_code )
  $logger.close
  exit exit_code
end

def print_exception( message, e )
  $logger.fatal( "#{message}. (#{e.message})" )
  e.backtrace.each {|bt| $logger.fatal( bt )}
end

# --------
#   Main
# --------

# -- Setup --

# Get the configuration.
begin
  config = YAML.load( File.read( CONFIG_PATH ) )
  unless config.class == Array
    raise "Only an array of folders is accepatable as configuration data."
  end
rescue
  print_exception( "Could not load YAML file", $! )
  quit 1
end
$logger.debug( "Arguments: #{config.inspect}" )

# Make sure folders exist in /backup.
backups = []
config.each do |folder|
  begin
    source_path = "/#{folder}"
    target_path = "#{BACKUP_PATH}/#{folder}"

    $logger.debug( "Searching for #{source_path} to backup to #{target_path}.")
    unless Dir.exists?( source_path )
      raise "No #{source_path} mounted."
    else
      Dir.mkdir( target_path ) unless Dir.exists?( target_path )
      backups << Backup.new( source_path, target_path, $logger )
    end
  rescue
    print_exception( "Problem while validating '#{folder}'", $! )
    quit 1
  end
end

# -- Perform the Backup --
cmd = ARGV.shift

begin
  backups.each do |backup|
    case cmd
    when 'hourly'
      $logger.warn( "Performing hourly backups." )
      backup.hourly_snapshot!
    when 'daily'
      $logger.warn( "Performing daily backups." )
      backup.daily_snapshot!
    when 'monthly'
      $logger.warn( "Performing monthly backups." )
      backup.monthly_snapshot!
    else
      raise "Unknown command '#{cmd}'."
    end
    $logger.warn( "Backup completed." )
  end
rescue
  print_exception( 'Exception occurred', $! )
  quit 1
end

quit 0
