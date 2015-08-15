#!/bin/sh

g++ -I /usr/include/mysql/ -o mysql.so -shared mysql-damlev.cpp
