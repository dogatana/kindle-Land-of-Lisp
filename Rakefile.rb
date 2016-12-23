require 'utils'

EPUB_FILE  = 'Land_of_Lisp.epub'
TARGET_DIR = 'temp'

mkdir TARGET_DIR unless File.exist?(TARGET_DIR)

task :default => [:unzip, :fix_img, :fix_ncx, :add_pagebreak, :make_kindle]
#task :default => [:fix_img, :fix_ncx, :add_pagebreak, :make_kindle]

desc 'unzip epub'
task :unzip do
  unzip(EPUB_FILE, TARGET_DIR)
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

desc 'add pagebreak in index.html'
task :add_pagebreak do
  add_pagebreak("#{TARGET_DIR}/index.html")
end

task :make_kindle do
  chdir TARGET_DIR do
    sh 'kindlegen content.opf -o Land_of_Lisp.mobi'
  end
end
