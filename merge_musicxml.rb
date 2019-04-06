require 'nokogiri'

$score = nil
$scores = nil

# load files
scores = [
  Nokogiri(File.read("xml/score1.xml")),
  Nokogiri(File.read("xml/score2.xml"))
]

score = scores.shift

id = score.at 'identification'

# add work info:
# <score-partwise>
id.add_previous_sibling <<-END
  <work>
   <work-title>Combined Dorico Scores</work-title>
  </work>
END

measure_offset = (score.at("part[id='P1']") / "measure").size

# iterate over scores / parts
scores.each do |s|
  # iterate over measures for each part
  # increment measure number for additional scores
  (s / "part").each do |part|
    # puts part.to_xml
    score_part = score.at("part[id='#{part['id']}']")
    (part / "measure").inject(measure_offset + 1) do |measure_number, measure|
      measure['number'] = measure_number
      score_part.add_child measure
      measure_number + 1
    end
  end

  # print new page:
  # <measure number="3">
  #   <print new-page="yes" />

  # add metronome marker:
  # </attributes>
  # <direction>
  #  <direction-type>
  #   <metronome>
  #    <beat-unit>quarter</beat-unit>
  #    <per-minute>125</per-minute>
  #   </metronome>
  #  </direction-type>
  # </direction>

  # add system text:
  # <direction>
  #  <direction-type>
  #   <words>Part 2</words>
  #  </direction-type>
  # </direction>
  # <note>
end

# write xml document
File.open("xml/out.xml", "w") {|f| f << score.to_xml }
$score = score
$scores = scores
