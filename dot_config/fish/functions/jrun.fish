function jrun
    set file $argv[1]
    set name (string replace -r '\.java$' '' $file)
    /usr/lib/jvm/default/bin/javac $file
    and /usr/lib/jvm/default/bin/java -cp . $name
end
