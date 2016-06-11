Scripts to manipulate files
===========================


`prefix_date_time.sh`
---------------------

* Search JPEG files
* Extract `date` and `time` from EXIF (else from file properties)
* Insert `date` and `time` in the beginning of the filename  
  using the format `YYYYMMDD_HHMMSS_<oldname>.JPG`

Usage:

    prefix_date_time.sh [directory1] [directory2]...

Example:

    $ ls
    ABCDEF.jpg

    $ prefix_date_time.sh
    This script will rename JPEG files in current directory and subdirectories.
    Current directory: /tmp/test-oli
    The renaming consists in prefixing current filename with date and time.
    Ready to continue? (y/n) y
    Not JPEG: ./abcdef.JPG
    ./ABCDEF.jpg
    ./ABCDEF.jpg --> ./20150110_103844_ABCDEF.jpg
    
    $ ls
    20150110_103844_ABCDEF.jpg

This script is based on [`jhead`](http://www.sentex.net/~mwandel/jhead/).  
=> Install `jhead` before using this script.


`delete-orf-orphans.sh`
-----------------------

RAW and JPEG files comme in pair, same filename but different extension.  
But when deleting the pictures, most of the tools remove only the JPEG files.
This script help removing the orphan RAW files.


This script try to identify RAW files  detect is based on filemane reconition between `*.ORF` files (RAW files) and JPEG files.
The related RAW and JPEG filenames must 

* Search for `*.ORF` files
* Extract the identifier part from the `*.ORF` filename (the original filename)
* Search for JPEG filenames containing this identifier
* If no JPEG found, consider the 





delete-orf-orphans.sh 	Set `chmod +x` 	a day ago
	prefix_date_time.sh 	Add two new scripts for image files cleaning 	a day ago
	rmdups.sh 	Remove trailing whitespaces 	a day ago
	rmdups2.sh 	Remove trailing whitespaces 	a day ago
	same_name_as_jpeg.sh
	




rmdups.sh
============

This *unmaintanable* bash script aims to help in the difficult job to choose the right duplicated files to remove.

##### Other alternatives (more mature and faster)
- [Duplicate file finders on Wikipedia](https://en.wikipedia.org/wiki/List_of_duplicate_file_finders)
- [fslint](http://www.pixelbeat.org/fslint/)
- `duff`
- [`fdups`](http://en.wikipedia.org/wiki/Fdupes)
- [`rmlint`](https://github.com/sahib/rmlint)
- ... (proposes yours here)

##### Also handling similar image content
- [`findimagedups` from Jonathan H N Chin](http://www.jhnc.org/findimagedupes/), perl script (and C lib) storing image fingerprints into a Berkley DB file and printing together filenames of images matching more than xx% similarity (pictures taken in burst mode may be flagged as similar)
- [`findimagedupes` version in Go](https://github.com/opennota/findimagedupes)
- [gThumb](https://en.wikipedia.org/wiki/GThumb) can also [find/remove duplicates](http://www.webupd8.org/2011/03/gthumb-2131-released-with-find.html)
- [Geeqie](https://en.wikipedia.org/wiki/Geeqie)
- [imgSeek](http://www.imgseek.net/)
- [digiKam](https://en.wikipedia.org/wiki/DigiKam) and its [Find Duplicate Images Tool](http://www.digikam.org/node/333)
- [Visipics](www.visipics.info)
- [dupeGuru Picture Edition](http://www.hardcoded.net/dupeguru_pe/)
