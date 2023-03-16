# Bash exit codes

| Exit Code Number | Meaning             | Comments |
| ---------------- | ------------------- | -------- |
| 1     | Catchall for general errors    | Miscellaneous errors, such as "divide by zero" and other impermissible operations |
| 2     | Misuse of shell builtins       | Missing keyword or command, or permission problem (and diff return code on a failed binary file comparison) |
| *124* | You need to be root            | System script started as a non-root user |
| *125* | Unconfigured                   | Missing configuration file or value |
| 126   | Command invoked cannot execute | Permission problem or command is not an executable |
| 127   | "command not found"            | Possible problem with `$PATH` or a typo |
| 128   | Invalid argument to exit       | exit takes only integer args in the range 0 - 255 |
| 128+n | Fatal error signal "n"         | `$?` returns 137 (128 + 9) |
| 130   | Script terminated by Control-C | Control-C is fatal error signal 2, (130 = 128 + 2, see above) |
| 255   | Exit status out of range       | exit takes only integer args in the range 0 - 255 |

Source: [Advanced Bash-Scripting Guide Appendix E.](https://www.tldp.org/LDP/abs/html/exitcodes.html)

Custom Exit Code Numbers are marked in *italic*.
