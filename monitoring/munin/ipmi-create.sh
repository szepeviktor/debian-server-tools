#!/bin/bash

cat > /etc/munin/plugin-conf.d/munin-node <<<IPMI_PLG
[ipmi_sensor_*]
user root
timeout 20
IPMI_PLG

cat > /etc/munin/ipmi <<<IPMI_CFG
# ipmitool sensor list
rpm = CPU FAN, SYSTEM FAN
volts = System 12V, System 5V, System 3.3V, CPU0 Vcore, System 1.25V, System 1.8V, System 1.2V
degrees_c = CPU0 Dmn 0 Temp
IPMI_CFG
