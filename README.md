# ico - Isilon Calculate Overhead

Simple tool for calculating storage overhead for given file or directory on DellEMC Isilon (OneFS).

## Installing

Download ico.sh to one of the cluster nodes.
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

Show data for /ifs/data/test.pdf file.
```
/root/bin/ico.sh -f /ifs/data/test.pdf
```
```
Summary for: /ifs/data/test.pdf
 Isilon Data: 7.50 MiB
 File Size: 2.40 MiB
 Overhead: 212.00 %
 Efficiency: 32.00 %
 Requested Protection: 3x
 Actual Protection: 3x
```

Show data for "/ifs/data/software packages" directory; displays progress of the entire operation.

```
/root/bin/ico.sh -d /ifs/data/software\ packages
```
```
1283/1283
Summary for: /ifs/data/software packages
 Isilon Data: 41.71 GiB
 All Files (1283) Size: 30.48 GiB
 Overhead: 36.00 %
 Efficiency: 73.00 %
```

