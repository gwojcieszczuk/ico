# ico - Isilon Calculate Overhead

Simple tool for calculating storage overhead for given file or directory on DellEMC Isilon (OneFS).

## Installing

Download ico.sh to one of the cluster nodes. If Isilon node has internet access you can use curl to download it.

```
curl -k https://raw.githubusercontent.com/gwojcieszczuk/ico/master/ico.sh > ico.sh
```

```
mkdir /root/bin
cp ico.sh /root/bin
chmod 550 /root/bin/ico.sh
```

## Syntax

Show syntax

```
/root/bin/ico.sh
```
```
/root/bin/ico.sh -f /ifs/<path to file>
/root/bin/ico.sh -d /ifs/<path to directory>
```

Show storage overhead and efficiency for given filename (use tab-completion)

```
/root/bin/ico.sh -f /ifs/data/test.pdf
```

Show storage overhead and efficiency for given directory (use tab-completion)

```
/root/bin/ico.sh -d /ifs/data/software\ packages
```

## Sample output

Show data for **/ifs/data/test.pdf** file.
```
/root/bin/ico.sh -f /ifs/data/test.pdf
```
```
Summary for: /ifs/data/test5.dd
 Processing Time: 00h 00min 00sec
 Today is: 2019-05-30 08:40
 Isilon Data: 27.00 MiB
 File Size: 20.00 MiB
 Overhead: 25.00 %
 Efficiency: 74.00 %
 Requested Protection: default
 Actual Protection: +2d:1n
```

Show data for **/ifs/data/software packages** directory; displays progress of the entire operation.

```
/root/bin/ico.sh -d /ifs/data/software\ packages
```
```
Processing 1283 files (in batches of 1000)... 
1283/1283
Summary for: /ifs/data/software packages
 Processing Time: 00h 00min 13sec
 Today is: 2019-05-30 08:41
 Isilon Data: 41.71 GiB
 All Files (1283) Size: 30.48 GiB
 Overhead: 36.00 %
 Efficiency: 73.00 %
```

