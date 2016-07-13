### CPU benchmarks

```bash
# Mini, one thread, all threads, 4 times overload
apt-get install -y sysbench
sysbench --test=cpu --cpu-max-prime=100000 run --num-threads=1 --max-requests=100
sysbench --test=cpu --cpu-max-prime=100000 run --num-threads=1
sysbench --test=cpu --cpu-max-prime=100000 run --num-threads=$(grep -c "^processor" /proc/cpuinfo)
sysbench --test=cpu --cpu-max-prime=100000 run --num-threads=$((4 * $(grep -c "^processor" /proc/cpuinfo)))
```

### WordPress speedtest

```bash
apt-get clean; apt-get update
apt-get install -y php5-cli php5-sqlite
wget -qO- https://github.com/szepeviktor/wordpress-speedtest/releases/download/v0.1.2/wordpress-speedtest.tar.gz|tar xzv
cd wordpress-speedtest

time php index.php | grep -q 'Hello world.</a></h2>' || echo "WordPress error." >&2
# 10×
time for R in {1..10}; do php index.php > /dev/null; done
# Stability
while :; do { time php index.php > /dev/null; sleep 0.2; } 2>&1|grep "^real"; done
```

### Comparision table

https://www.cpubenchmark.net/singleThread.html

@TODO Table columns:
- date
- CPU model
- UnixBench
- seekmark us
- sysbench ms
- network speeds
- WP speed
- image speed

@TODO Measure: CPU speed bz2 25MB, disk access time and throughput hdd-, network speed multiple connections
https://github.com/mgutz/vpsbench/blob/master/vpsbench
See: monitoring/cpu-speed/image-benchmark.sh

- VPS hosting results (http ms, ping ms)

SoYouStart by OVH / E3-SSD-3 JPEG 1:20, 0:10 sysbench 20 ms
OVH cloud vps rbx2 sysbench 45ms
OVH Public Cloud / CPU instance E312xx (Sandy Bridge) sysbench 23 ms


```
system         | result (s)
---------------|-----------
DO             |        314
Li             |        303
power8 ×176    |          9
power8 small×8 |         57
FORPSI Smart   |        325
vps5 X3440×2   |         89
RunAbove labs  |        215
```


### JPEG minification

- imgmin https://github.com/rflynn/imgmin/tree/e64807bc613ef0310910a5030ed4e5bd8bfeeefc/examples
- jpeg-recompress https://www.dropbox.com/s/hb3ah7p5hcjvhc1/jpeg-archive-test-files.zip
