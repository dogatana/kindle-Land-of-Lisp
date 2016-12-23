require 'nokogiri'
require 'fastimage'

EPUB_DIR = 'epub/OEBPS'
TARGET_DIR = 'kindle'

mkdir TARGET_DIR unless File.exist?(TARGET_DIR)

DIGIT_TABLE = {
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


def negative_circled_digit(node)
  code_point = DIGIT_TABLE[node['src']]
  if code_point
    node.name = 'span'
    node.attributes.each { |name, _| node.remove_attribute(name) }
    node << code_point
  end
end

def fix_img_tag(file)
  html = open(file, 'r:utf-8', &:read)
  doc = Nokogiri::HTML.parse(html)
  dirty = false
  doc.xpath('//img').each do |tag|
    image_file = "#{TARGET_DIR}/#{tag['src']}"
    width, height = *FastImage.new(image_file).size
    if width < 20
      negative_circled_digit(tag)
    else
      tag['width'] = width * 2
      tag['height'] = height * 2
      tag.remove_attribute('alt')
    end
    dirty = true
  end
  if dirty
    doc.xpath('//div[@class="mediaobject"]').each do |tag|
      tag['align'] = 'center'
      puts tag
    end
  end
  return unless dirty
  open(file, 'w:utf-8').write(doc.to_html)
end

def fix_ncx(file)
  puts file
  xml = open(file, 'r:utf-8', &:read)
  xml = xml.sub(/<navPoint.*?<navPoint/m, '<navPoint')
           .sub(/<\/navPoint>\s+<\/navMap>/m, '</navMap>')
  open(file, 'w:utf-8').write(xml)
end

def add_pagebreak(file)
  html = open(file, 'r:utf-8', &:read)
  new_html = html.sub(%r|<hr/></div>|, '<hr/></div><mbp:pagebreak />')
  open(file, 'w:utf-8').write(new_html)
end


desc 'copy files to kindle'
task :copy_file do
  cp Dir["#{EPUB_DIR}/*"], TARGET_DIR
end

desc 'fix img tag'
task :fix_img do
  Dir["#{TARGET_DIR}/*.html"].each do |file|
    fix_img_tag(file)
  end
end

desc 'fix ncx file'
task :fix_ncx do
  fix_ncx("#{TARGET_DIR}/toc.ncx")
end

desc 'add pagebreak'
task :add_pagebreak do
  add_pagebreak("#{TARGET_DIR}/index.html")
end
