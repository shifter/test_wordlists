#!/usr/bin/env ruby


EXPECTED_SIZE = 1626
DATA_DIR = "data"

def normalize_string!(str)
  # Spanish
  str.sub!(/á/, "a")
  str.sub!(/é/, "e")
  str.sub!(/í/, "i")
  str.sub!(/ó/, "o")
  str.sub!(/ú/, "u")
  str.sub!(/ñ/, "n")

  # German
  str.sub!(/[äÄ]/, "a")
  str.sub!(/[öÖ]/, "o")
  str.sub!(/[üÜ]/, "u")
  # ß is distinct enough, leave alone?
end

def check_normal(str)
  str.chars.each do | x |
    if x !~ /[a-zA-Z]/
      puts "WARNING: not a regular alphabetic character: #{x} in #{str}"
    end
  end
end

def check_words(words, prefix_length, replace_irregular_chars)
  h = {}
  words.each do | word |
    prefix = word[0, prefix_length]
    if prefix.size < prefix_length
      puts "NOTE: word size for #{word} is < prefix length #{prefix_length}"
    end
    prefix.downcase!

    if replace_irregular_chars
      normalize_string!(prefix) 
      check_normal(prefix)
    end

    h[prefix] ||= []
    h[prefix] << word
  end

  failed = {}
  h.each_pair do |k , v|
    if v.size > 1
      failed[k] = v
    end
  end

  if failed.empty?
    puts "PASS"
  else
    puts "FAIL"
    failed.each_pair do |k, v|
      print "WARNING for prefix [#{k}]: " 
      puts v.join(" ")
    end
  end
end

def validate(wordlist)
  replace_irregular_chars = true

  if wordlist.is_a?(Array)
    wordlist_file, options = wordlist
    if options.include?("replace_irregular_chars")
      replace_irregular_chars = options["replace_irregular_chars"]
    end
  else
    wordlist_file = wordlist
  end

  puts "Wordlist: #{wordlist_file}"

  words = File.readlines(File.join(DATA_DIR, wordlist_file))

  res = words.select {|x| x =~ /unique_prefix_length\s*=/ }
  if res.size > 1
    warn "Too many possible prefix lengths in word list"
    abort "Aborting"
  elsif res.empty?
    warn "No prefix length found in word list"
    abort "Aborting"
  else
    matches =  res.first.match(/unique_prefix_length\s*=\s*(\d+)/)
    if matches
      prefix_length = matches[1].to_i
    else
      warn "No prefix length found in word list"
      abort "Aborting"
    end
  end

  puts "Unique prefix length: #{prefix_length}"

  words.map! {|x| x.strip}
  words.reject! {|x| x == "" || x =~ /^#/}
  words.map! {|x| x.gsub(/[",]/, '')}

  puts "Total words: #{words.size}"
  if words.size != EXPECTED_SIZE
    warn "WARNING: wordlist size is #{words.size} instead of expected #{EXPECTED_SIZE} words"
  end

  check_words(words, prefix_length, replace_irregular_chars)
end


wordlists = [
  "wordlist_english.txt",
  # "wordlist_old_english.txt",
  "wordlist_portuguese.txt",
  "wordlist_spanish.txt",
  ["wordlist_japanese.txt", {"replace_irregular_chars" => false}],
  "wordlist_german.txt"
]

wordlists.each do | wordlist |
  validate(wordlist)
  puts "\n\n"
end

