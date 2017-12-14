### CPU benchmark

```bash
# Mini, one thread, all threads, 4 times overload
apt-get install -y sysbench
sysbench --test=cpu --cpu-max-prime=100000 run --num-threads=1 --max-requests=100
sysbench --test=cpu --cpu-max-prime=100000 run --num-threads=1
sysbench --test=cpu --cpu-max-prime=100000 run --num-threads=$(grep -c "^processor" /proc/cpuinfo)
sysbench --test=cpu --cpu-max-prime=100000 run --num-threads=$((4 * $(grep -c "^processor" /proc/cpuinfo)))
```

### WordPress speedtest

See https://github.com/szepeviktor/wordpress-speedtest

### JPEG minification

- imgmin https://github.com/rflynn/imgmin/tree/e64807bc613ef0310910a5030ed4e5bd8bfeeefc/examples
- jpeg-recompress https://www.dropbox.com/s/hb3ah7p5hcjvhc1/jpeg-archive-test-files.zip

### Comparision

https://www.cpubenchmark.net/singleThread.html
