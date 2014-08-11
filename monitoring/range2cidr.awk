#!/usr/bin/awk -f
#
# Library with various ip manipulation functions
#
# VERSION       :1.0
# DATE          :2014-08-01
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# LOCATION      :/usr/local/bin/range2cidr.awk
# SOURCE        :http://www.unix.com/shell-programming-and-scripting/233825-convert-ip-ranges-cidr-netblocks.html


# convert ip ranges to CIDR notation
#   str range2cidr(ip2dec("192.168.0.15"), ip2dec("192.168.5.115"))
#
# Credit to Chubler_XL for this brilliant function. (see his post below for non GNU awk)
#
function range2cidr(ipStart, ipEnd,  bits, mask, newip) {
    bits = 1
    mask = 1
    result = ""
    while (bits < 32) {
        newip = or(ipStart, mask)
        if ((newip>ipEnd) || ((lshift(rshift(ipStart,bits),bits)) != ipStart)) {
           bits--
           mask = rshift(mask,1)
           break
        }
        bits++
        mask = lshift(mask,1)+1
    }
    newip = or(ipStart, mask)
    bits = 32 - bits
    result = result dec2ip(ipStart) "/" bits
    if (newip < ipEnd) result = result "\n" range2cidr(newip + 1, ipEnd)
    return result
}

# convert dotted quads to long decimal ip
#   int ip2dec("192.168.0.15")
#
function ip2dec(ip,   slice) {
    split(ip, slice, ".")
    return (slice[1] * 2^24) + (slice[2] * 2^16) + (slice[3] * 2^8) + slice[4]
}

# convert decimal long ip to dotted quads
#   str dec2ip(1171259392)
#
function dec2ip(dec,    ip, quad) {
    for (i=3; i>=1; i--) {
        quad = 256^i
        ip = ip int(dec/quad) "."
        dec = dec%quad
    }
    return ip dec
}


# convert decimal ip to binary
#   str dec2binary(1171259392)
#
function dec2binary(dec,    bin) {
    while (dec>0) {
        bin = dec%2 bin
        dec = int(dec/2)
    }
    return bin
}

# Convert binary ip to decimal
#   int binary2dec("1000101110100000000010011001000")
#
function binary2dec(bin,   slice, l, dec) {
    split(bin, slice, "")
    l = length(bin)
    for (i=l; i>0; i--) {
        dec += slice[i] * 2^(l-i)
    }
    return dec
}

# convert dotted quad ip to binary
#   str ip2binary("192.168.0.15")
#
function ip2binary(ip) {
    return dec2binary(ip2dec(ip))
}


# count the number of ip's in a dotted quad ip range
#   int countIp ("192.168.0.0" ,"192.168.1.255") + 1
#
function countQuadIp(ipStart, ipEnd) {
    return (ip2dec(ipEnd) - ip2dec(ipStart))
}


# count the number of ip's in a CIDR block
#   int countCidrIp ("192.168.0.0/12")
#
function countCidrIp (cidr) {
    sub(/.+\//, "", cidr)
    return 2^(32-cidr)
}


BEGIN{
#    print range2cidr(ip2dec(ARGV[1]), ip2dec(ARGV[2]))
    if (ARGV[2] == "-") print range2cidr(ip2dec(ARGV[1]), ip2dec(ARGV[3]))
    else print range2cidr(ip2dec(ARGV[1]), ip2dec(ARGV[2]))
}
