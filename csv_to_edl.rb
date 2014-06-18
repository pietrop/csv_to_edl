require 'csv'
require 'timecode'

=begin
the idea was to pass the CSV into an array of row object,
where each row has the properties of the cell in the rows
and the iterate over this array of objects into a EDL paragraph to output.
so that a edl file could be created
=end

#CSV tutorial http://www.sitepoint.com/guide-ruby-csv-library-part/

#when running in terminal, writing $ ruby csv_to_edl_v1.rb TestProject.csv
#takes the first argument after the filename.
filename = ARGV.first

#Opening CSV file, which is array of arrays, where each line is an array, like this
#[["tc_in", "tc_out", "REEL", "tc_meta", "clip_name"], ["0:02:38", "0:02:42", "CHRISTOPHER_CLEARY_RADIOONEDOCS", nil, "CC0027_01.MOV"], ["0:02:42", "0:02:46", "CHRISTOPHER_CLEARY_RADIOONEDOCS", nil, "CC0027_01.MOV"], ["0:00:47", "0:00:51", "CARLENE_MORLESE_RADIOONE", nil, "CM0002_01.MOV"], ["0:00:51", "0:00:54", "CARLENE_MORLESE_RADIOONE", nil, "CM0002_01.MOV"], ["0:02:53", "0:03:00", "LYNDA_HARRISON_WATCHDOG", nil, "LH0005_01.MOV"]]

PaperEdit = CSV.read(filename)

#line count for EDL
n=0

#array of CSV line objects
a =[]

class Row
  attr_accessor :n, :tc_in,:tc_out,:reel,:tc_meta,:clip_name, :time, :rec_in, :rec_out
  def initialize(n, tc_in,tc_out,reel,tc_meta,clip_name)
    @n, @tc_in, @tc_out, @reel, @tc_meta, @clip_name = n,tc_in, tc_out,reel,tc_meta,clip_name
     # @tc_in = Timecode.parse_with_fractional_seconds("0"+ tc_in, fps = 25)
  end

  def time_in
    # @tc_in = "00:0"+@tc_in
    @time_in = Timecode.parse("#{@tc_in}", fps = 25)
  end

  def time_out
    # @tc_out = "00:0"+@tc_out
    @time_out = Timecode.parse("#{@tc_out}", fps = 25)
  end

  def tc_meta
    @tc_meta =  Timecode.parse("#{@tc_meta}", fps = 25)
  end

  def rec_in
      @rec_in = Timecode.parse("00:00:00:00",fps = 25)
  end

  def rec_out
    @rec_out = @time_out - @time_in + @rec_in
  end

end

#goes through each line of the CSV filename[ line 1 of csv ] etc..
CSV.foreach(filename) do |r|

  n = n +  1
# each line each looks like this
# ["tc_in", "tc_out", "REEL", "tc_meta", "clip_name"]
# ["0:02:38", "0:02:42", "CHRISTOPHER_CLEARY_RADIOONEDOCS", nil, "CC0027_01.MOV"]
# so we can isolate each value using array indexing r[0] etc..
  p = Row.new(n, r[2],r[3],r[4],r[5],r[6]) #r[0],r[1]
  #we can then ad the Row.new object assigned to p to an array that is storing all the
  #lines as objects for easier retrival when we'll loop through them again for the EDL output
  a << p
end

# puts a.inspect

#remove header column array ["tc_in", "tc_out", "REEL", "tc_meta", "clip_name"]
a.shift

body = ""
# puts a.inspect

title ="TITLE: #{filename.split(".")[0].upcase}\nFCM: NON-DROP FRAME\n\n"

 rec_in = Timecode.parse("00:00:00:00", fps = 25)
a.each do |l|

  rec_out =  l.time_out - l.time_in + rec_in
body << <<-PARAGRAPH
00#{l.n}  #{l.reel[0..7]} AA/V  C #{l.time_in + l.tc_meta} #{l.time_out + l.tc_meta} #{rec_in} #{rec_out}
* FROM CLIP NAME:  #{l.clip_name.upcase}
* COMMENT:#{" "}
FINAL CUT PRO REEL: #{l.reel.upcase} REPLACED BY: #{l.reel[0..7].upcase}
  PARAGRAPH

rec_in = rec_out

  end

puts title + body

File.open("#{filename.split('.')[0]}.edl", 'w') { |file| file.write(title+body) }

puts "edl #{filename.split('.')[0]}.edl saved "




