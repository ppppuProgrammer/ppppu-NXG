extends Node

#Simple logging class
const LOG_FOLDER = "user://Logs"
#Path to current log for this session.
var log_name:String 
enum level { ALL, DEBUG}
func _ready():
	#Create the logs folder if it doesn't exist
	var logFolder:Directory = Directory.new()
	if !logFolder.dir_exists(LOG_FOLDER):
		logFolder.make_dir(LOG_FOLDER)
	var logFile:File = File.new()
	var datetime:Dictionary = OS.get_datetime()
	log_name = LOG_FOLDER + "/log_%d%02d%02d-%02d%02d%02d" % [datetime["year"], 
			datetime["month"], datetime["day"], datetime["hour"], 
			datetime["minute"], datetime["second"]]
	logFile.open(log_name, File.WRITE_READ)
	var header:String = "%s Version %s" % [GameVersion.GAME_NAME, 
		GameVersion.GAME_MAJOR_VER]
	if GameVersion.GAME_MINOR_VER.length() > 0:
		header += ".%s" % GameVersion.GAME_MINOR_VER
	if GameVersion.GAME_VER_TAG.length() > 0:
		header += "(%s)" % GameVersion.GAME_VER_TAG
	logFile.store_string(header)
	logFile.store_string(_get_system_info())
	logFile.close()
	
func _get_system_info():
	var systemStr = "Operating System: %s\nProcessor Count: %d" % [OS.get_name(), OS.get_processor_count()]
	var videoStr = "Available video drivers:"
	for videoDriverNum in OS.get_video_driver_count():
		videoStr += "\n\t%s" % OS.get_video_driver_name(videoDriverNum)
	return "%s\n%s" % [systemStr, videoStr]
	
func append(text:String, log_level:int = ALL):
	if log_level == DEBUG and !OS.is_debug_build():
		return
	var logFile:File = File.new()
	logFile.open(log_name, File.READ_WRITE)
	logFile.seek_end()
	logFile.store_string("\n" + text)
	logFile.close()