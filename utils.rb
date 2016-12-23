# frozen_string_literal: true
require 'nokogiri'
require 'fastimage'
require 'zip'

MAGNIFY = 2.0

DIGIT_TABLE = {
  # image file                                       =>  circle, negative circle
  'httpatomoreillycomsourcenostarchimages783564.png' => "\u2460", # "\u2776"
  'httpatomoreillycomsourcenostarchimages783562.png' => "\u2461", # "\u2777"
  'httpatomoreillycomsourcenostarchimages783560.png' => "\u2462", # "\u2778"
  'httpatomoreillycomsourcenostarchimages783554.png' => "\u2463", # "\u2779"
  'httpatomoreillycomsourcenostarchimages783510.png' => "\u2464", # "\u277a"
  'httpatomoreillycomsourcenostarchimages783544.png' => "\u2465", # "\u277b"
  'httpatomoreillycomsourcenostarchimages783556.png' => "\u2466", # "\u277c"
  'httpatomoreillycomsourcenostarchimages783566.png' => "\u2467", # "\u277d"
  'httpatomoreillycomsourcenostarchimages783498.png' => "\u2468", # "\u277e"
  'httpatomoreillycomsourcenostarchimages783062.png' => "\u2469", # "\u277f"
}.freeze

# unzip epub into dst_dir
def unzip(zip_file, dst_dir)
  Zip::File.open(zip_file).each do |entry|
    next unless entry.name =~ /OEBPS/
    name = "#{dst_dir}/#{File.basename(entry.name)}"
    entry.extract(name) { true }
  end
end

# change <img> to <span>
def circled_digit(node)
  code_point = DIGIT_TABLE[node['src']]
  return unless code_point
  node.name = 'span'
  node.attributes.each { |name, _| node.remove_attribute(name) }
  node << code_point
end

# specify image size that is enlarged by FACTOR
def change_size(node, width)
  node['width'] = (width * MAGNIFY).to_i
  node.remove_attribute('alt')
end

# modify img tag
def fix_img_tag(file)
  html = open(file, 'r:utf-8', &:read)
  doc = Nokogiri::HTML.parse(html)
  dirty = false
  doc.xpath('//img').each do |tag|
    image_file = "#{TARGET_DIR}/#{tag['src']}"
    width, = *FastImage.new(image_file).size
    if width < 20
      circled_digit(tag)
    else
      change_size(tag, width)
    end
    dirty = true
  end
  if dirty
    doc.xpath('//div[@class="mediaobject"]').each do |tag|
      tag['align'] = 'center'
    end
  end
  return unless dirty
  File.open(file, 'w:utf-8') { |f| f.write(doc.to_html) }
end

# Kindle can handle two-level index as most
def fix_ncx(file)
  puts file
  xml = open(file, 'r:utf-8', &:read)
  xml = xml.sub(/<navPoint.*?<navPoint/m, '<navPoint')
           .sub(%r{</navPoint>\s+</navMap>}m, '</navMap>')
  File.open(file, 'w:utf-8') { |f| f.write(xml) }
end

# add pagebreak before Dedication
def add_pagebreak(file)
  html = open(file, 'r:utf-8', &:read)
  new_html = html.sub(%r{<hr/></div>}, '<hr/></div><mbp:pagebreak />')
  File.open(file, 'w:utf-8') { |f| f.write(new_html) }
end
