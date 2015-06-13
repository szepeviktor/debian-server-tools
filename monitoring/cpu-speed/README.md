### CPU benchmarks

```bash
# One thread, all threads, 4 times overload
#apt-get install -y time sysbench
time sysbench --test=cpu --cpu-max-prime=100000 run --num-threads=1 #--max-requests=1000
time sysbench --test=cpu --cpu-max-prime=100000 run --num-threads=$(grep -c "^processor" /proc/cpuinfo)
time sysbench --test=cpu --cpu-max-prime=100000 run --num-threads=$((4 * $(grep -c "^processor" /proc/cpuinfo)))
```

https://www.cpubenchmark.net/singleThread.html
- date
- CPU model
- UnixBench
- seekmark us
- sysbench ms
- network speeds

# @TODO measure CPU speed bz2 25MB, disk access time and throughput hdd-, network speed multiple connections
# https://github.com/mgutz/vpsbench/blob/master/vpsbench
# See: monitoring/cpu-speed/image-speed.sh

- hosting results (http ms, ping ms)

```
system         | result (s)
---------------|-----------
power8 ×176    |          9
power8 small×8 |         57
FORPSI Smart   |        325
vps5 X3440×2   |         89
RunAbove labs  |        215
```


### JPEG minification

- imgmin + https://github.com/rflynn/imgmin/tree/e64807bc613ef0310910a5030ed4e5bd8bfeeefc/examples
- jpeg-recompress + https://www.dropbox.com/s/hb3ah7p5hcjvhc1/jpeg-archive-test-files.zip
