#!/usr/bin/ruby

require 'find'
require 'set'
require 'tempfile'
require 'ftools'

$VERBOSE = true

def fix_file(file)
  puts "Fixing #{file}"
  Tempfile.open("temp") do |temp|
    path = temp.path()
    #temp.unlink

    File.open(file) do |f|
      f.each do |line|
        line.chomp!
        temp.print "#{line}\n"
      end
    end
    
    temp.flush()
    temp.close()
    
    File.syscopy(path, file)
    File.delete(path)
  end
end

excludes = Set.new %w{
  bmp class dmg doc exe gif gz jar jpeg jpg m4p mov mp3 mpeg mpg
  mv4 nib pdf png ppt psd rtf rtfd sit sitx tar tgz tif tiff wav xls zip
}

# Return the part of the file name string after the last '.'
def file_type( file_name )
    File.extname( file_name ).gsub( /^\./, '' ).downcase 
end

Find.find(ARGV[0]) do |file|
  extension = file_type(file)
  should_exclude = excludes.include?(extension)
  if FileTest.directory?(file)
    if should_exclude
      puts "Pruning #{file}"
      Find.prune
    else
      next
    end
  end
  
  is_dot_file = File.basename(file)[0] == ?.
  if should_exclude || is_dot_file
    puts "Skipping #{file}"
    next
  end

  fix_file(file)
end
