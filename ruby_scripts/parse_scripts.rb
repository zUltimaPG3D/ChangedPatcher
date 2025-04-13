def scripts
    File.open("./temp_scripts.rvdata", "rb") { |f|
        obj = Marshal.load(f)
    }
end

scr = scripts.each do |script|
    if script[2].is_a?(String)
        script[2] = script[2].bytes
    end
end

$RGSS_SCRIPTS = scr