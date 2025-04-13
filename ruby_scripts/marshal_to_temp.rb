file = File.open("./temp_scripts_new.rvdata", "wb")
Marshal.dump($RGSS_SCRIPTS, file)
file.close