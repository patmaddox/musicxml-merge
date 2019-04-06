require 'nokogiri'

$score = nil
$scores = nil

# load files
scores = [
  Nokogiri(File.read("xml/score1.xml")),
  Nokogiri(File.read("xml/score2.xml"))
]

score = scores.shift

score_partwise = score.at 'score-partwise'

# add work info:
# <score-partwise>
score_partwise.prepend_child <<-END
  <work>
   <work-title>Combined Dorico Scores</work-title>
  </work>
END

metronome = (score / "part[id='P1']" / "measure").first.at("attributes").add_next_sibling(<<-END
  <direction>
   <direction-type>
    <metronome>
     <beat-unit>quarter</beat-unit>
     <per-minute>50</per-minute>
    </metronome>
   </direction-type>
  </direction>
END
.strip).first

metronome.add_next_sibling(<<-END
  <direction>
   <direction-type>
    <words>Section 1</words>
   </direction-type>
  </direction>
END
.strip)

measure_offset = (score.at("part[id='P1']") / "measure").size

# iterate over scores / parts
scores.each_with_index do |s, i|
  # iterate over measures for each part
  # increment measure number for additional scores
  new_score = true

  (s / "part").each do |part|
    # puts part.to_xml
    score_part = score.at("part[id='#{part['id']}']")

    (part / "measure").inject(measure_offset + 1) do |measure_number, measure|
      measure['number'] = measure_number

      if new_score
        # print new page:
        # <measure number="3">
        #   <print new-page="yes" />

        measure.prepend_child '<print new-page="yes" />'
        attributes = measure.at 'attributes'

        metronome = attributes.add_next_sibling(<<-END
          <direction>
           <direction-type>
            <metronome>
             <beat-unit>quarter</beat-unit>
             <per-minute>125</per-minute>
            </metronome>
           </direction-type>
          </direction>
        END
        .strip).first
        $metronome = metronome
        # attributes.add_next_sibling metronome
        metronome.add_next_sibling(<<-END
          <direction>
           <direction-type>
            <words>Section #{i + 2}</words>
           </direction-type>
          </direction>
        END
        .strip)
        new_score = false
      end

      score_part.add_child measure
      measure_number + 1
    end
  end

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
