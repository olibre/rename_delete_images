Collection of bash scripts helping to rename or delete RAW and JPEG files:

* [`prefix_date_time.sh`](#prefix_date_timesh) insert "date" and "time" in filename's beginning (the alphabetical order is chronological).
* [`delete_orf_orphans.sh`](#delete-orf-orphanssh) delete orphan RAW files.
* [`same_name_as_jpeg.sh`](#same_name_as_jpegsh) rename RAW files using the same name as their corresponding JPEG files.
* [`rmdups.sh` and `rmdups2.sh`](#rmdupssh) to identify directories having the most duplicated files to delete.

My current personal usage
-------------------------

* Insert SD card in the computer and automount the filesystem
* Use `prefix_date_time.sh` in order to order images in chronological order (as my image-viewer orders only in alphabetical order)
* Manually delete pictures I do not want using my image-viewer (does not delete the RAW files)
* JPEG filename may be suffixed with some description 
* Use `delete_orf_orphans.sh` to delete the ORF files corresponding of the deleted JPEG file in the previous action
* Use `same_name_as_jpeg.sh` to keep consistency between JPEG and RAW filenames
* `rmdups.sh` is not used any more (neither `rmdups2.sh` which has not been completed) because presence of duplicates can help identifying directories containing images not having been deleted (this whole directory is a backup a should be deleted, and fresh backup should be redone)
* Backup content of SD card to computer


Filename constraints
--------------------

Filename extension              | Considered as...
--------------------------------|------------------
JPG or JPEG in case insensitive | JPEG file
ORF in case insensitive         | RAW file

Other extensions can be considered if other users [request](https://github.com/olibre/rename_delete_image_files/issues/new) it.

To find the corresponding RAW and JPEG files, the original filename set by the camera should be keept within the filename. This unique identifier is in the following case sensitive regex format:

    P[0-9A-Z][0-9]*
    
The identifier should be followed by any character among: `[._-]`

This last constraints can also evolve depending on [demand](https://github.com/olibre/rename_delete_image_files/issues/new).


`prefix_date_time.sh`
---------------------

* Search files that could contain EXIF data (generaly, JPEG files)
* Extract `date` and `time` from EXIF (else from file properties)
* Insert `date` and `time` in the beginning of the filename  
  using the format `YYYYMMDD_HHMMSS_<oldname>.JPG`

Command line usage:

    prefix_date_time.sh [directory1] [directory2]...

If no directory provided, search from current directory (and subdirectories).

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


`delete_orf_orphans.sh`
-----------------------

RAW and JPEG files comme in pair: same filename but different extension.  
When sorting and deleting the pictures, most of the time the deletion concerns only the JPEG files: the corresponding RAW files are kept. This script helps removing these orphan RAW files.

* Search for RAW files (at present only `*.ORF` files)
* Extract the identifier part from the RAW filename (e.g. the original filename from the camera)
* Search for JPEG filenames containing this same identifier
* If no JPEG found, the script considers the RAW file as orphan and the script deletes it
 
Command line usage:

    delete_orf_orphans.sh directory1 [directory2]

1. If only `directory1` is provided, the script will search both RAW and JPEG files in this directory (and subdirectories).
2. If two directories are provided, the script will search RAW files in `directory1` and JPEG files in `directory2`  
   (JPEG files in `directory1` are ignored, and same for RAW files in `directory2`)

The interest of this second option is lost. But this econd option is kept and will be documented when will be used...


`same_name_as_jpeg.sh`
----------------------
	
*Keep RAW and JPEG filenames consistent.*

* Search for JPEG files
* Extract the identifier part from the filename (e.g. the original filename from the camera)
* Skip if there are different filenames having same identifier
* Search for RAW filenames containing this same identifier
* Rename RAW filenames using the corrsponding JPEG filename

Command line usage:

    same_name_as_jpeg.sh [directory1] [directory2]...

If no directory provided, search from current directory (and subdirectories).


`rmdups.sh`
-----------

This Bash script helps in the difficult job to choose the most pertinent duplicated files to delete.

The ideas is to detect the directories containing the same duplicated files and to delete the duplicated files of the directory containing the most duplicated files. The user has a nice text-based interface to select the duplicates to delete.

However, the [initial script was very tiny](http://stackoverflow.com/questions/9144551/identifying-mp3-not-by-name-with-shell-script/9145286#9145286) and became a *bloat unmaintanable script* :-/

The second script `rmdups2.sh` was an attempt to optimize the processing speed (still based on Bash). But has never been completed because other tools already do similar job and faster.

##### Other alternatives (more mature and faster)

- [Duplicate file finders on Wikipedia](https://en.wikipedia.org/wiki/List_of_duplicate_file_finders)
- [fslint](http://www.pixelbeat.org/fslint/)
- `duff`
- [`fdups`](http://en.wikipedia.org/wiki/Fdupes)
- [`rmlint`](https://github.com/sahib/rmlint)
- ... (proposes yours here)

##### And tools even more powerful: can also detect similar image content

- [`findimagedups` from Jonathan H N Chin](http://www.jhnc.org/findimagedupes/), perl script (and C lib) storing image fingerprints into a Berkley DB file and printing together filenames of images matching more than xx% similarity (pictures taken in burst mode may be flagged as similar)
- [`findimagedupes` version in Go](https://github.com/opennota/findimagedupes)
- [gThumb](https://en.wikipedia.org/wiki/GThumb) can also [find/remove duplicates](http://www.webupd8.org/2011/03/gthumb-2131-released-with-find.html)
- [Geeqie](https://en.wikipedia.org/wiki/Geeqie)
- [imgSeek](http://www.imgseek.net/)
- [digiKam](https://en.wikipedia.org/wiki/DigiKam) and its [Find Duplicate Images Tool](http://www.digikam.org/node/333)
- [Visipics](www.visipics.info)
- [dupeGuru Picture Edition](http://www.hardcoded.net/dupeguru_pe/)

