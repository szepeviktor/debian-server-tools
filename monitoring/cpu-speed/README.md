### CPU benchmarks

```bash
# One thread, all threads, 4 times overload
time sysbench --test=cpu --cpu-max-prime=100000 run --num-threads=1
time sysbench --test=cpu --cpu-max-prime=100000 run --num-threads=$(grep -c "^processor" /proc/cpuinfo)
time sysbench --test=cpu --cpu-max-prime=100000 run --num-threads=$((4 * $(grep -c "^processor" /proc/cpuinfo)))
```

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
