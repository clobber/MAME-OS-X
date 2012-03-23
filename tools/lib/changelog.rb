
require 'hashes2ostruct'
require 'erb'

def fix_dates(changelog)
  changelog.each do |release|
    if !release.date.kind_of? Time
      release.date = Time.parse(release.date.to_s)
    end
  end
end

def read_changelog(file)
  changelog_yaml = ERB.new(IO.read(file), nil, '0').result
  changelog = hashes2ostruct(YAML.load(changelog_yaml))
  fix_dates(changelog)
  return changelog
end

def changelog2markdown(changelog, io)
  separator = ""
  changelog.each do |release|
    release_date = release.date.strftime("%d %b %Y")
    title = "Version #{release.version} -- #{release_date}"
    io.print separator
    io.puts title
    io.puts "-" * title.size
    io.puts
    release.changes.each do |change|
      io.puts "* " + change
    end
    separator = "\n\n"
  end
end
