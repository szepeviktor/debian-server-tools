### CPU benchmarks

```bash
sysbench --test=cpu --cpu-max-prime=100000 run --num-threads=8
```

```
system         | result (s)
---------------|-----------
power8 ×176    |          9
power8 small×8 |         57
FORPSI Smart   |        325
vps5 X3440×2   |         89

```


### JPEG minification

- imgmin + default set of images
