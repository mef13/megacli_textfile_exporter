# megacli_textfile_exporter
Megacli to prometheus textfile exporter(node_exporter)

To use this script, prometheus recommend using a `sponge` to atomically write the output.

   megacli.sh | sponge <output_file>

Sponge comes from [moreutils](https://joeyh.name/code/moreutils/)
* [brew install moreutils](http://brewformulas.org/Moreutil)
* [apt install moreutils](https://packages.debian.org/search?keywords=moreutils)
* [pkg install moreutils](https://www.freshports.org/sysutils/moreutils/)        

For more information see:
https://github.com/prometheus/node_exporter#textfile-collector
