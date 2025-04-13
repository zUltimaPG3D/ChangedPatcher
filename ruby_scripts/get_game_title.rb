def system
    f = File.open("./temp_system.rvdata", "rb")
    obj = Marshal.load(f)
    f.close
    
    obj
end

$game_title = system.game_title