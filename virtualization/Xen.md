# Xen server

### Prevent domU kernel detection by grub

```bash
echo "GRUB_DISABLE_OS_PROBER=true" >> /etc/default/grub
```
