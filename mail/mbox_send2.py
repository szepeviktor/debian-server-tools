#!/usr/bin/python
"""\
A command-line utility that can (re)send all messages in an mbox file
to a specific email address, with options for controlling the rate at
which they are sent, etc.
"""

# Upstream: https://gist.github.com/wojdyr/1176398#comment-1300024

# I got this script from Robin Dunn a few years ago, see
# https://github.com/wojdyr/fityk/wiki/MigrationToGoogleGroups

import sys
import os
import time
import mailbox
import email
import smtplib

from optparse import OptionParser, make_option


#---------------------------------------------------------------------------
# Set some defaults

defTo = []
defFrom = None
defChunkSize = 100
defChunkDelay = 30
defSmtpHost = 'localhost'
defSmtpPort = 25
defCount = -1
defStart = -1

# define the command line options
option_list = [
    make_option('--to', action='append', dest='toAddresses', default=defTo,
                help="The address to send the messages to.  May be repeated."),

    make_option('--from', dest='fromAddress', default=defFrom,
                help="The address to send the messages from."),

    make_option('--chunk', type='int', dest='chunkSize', default=defChunkSize,
                help='How many messages to send in each batch before pausing, default: %d' % defChunkSize),

    make_option('--pause', type='int', dest='chunkDelay', default=defChunkDelay,
                help='How many seconds to delay between chunks. default: %d' % defChunkDelay),

    make_option('--count', type='int', dest='count', default=defCount,
                help='How many messages to send before exiting the tool, default is all messages in the mbox.'),

    make_option('--start', type='int', dest='start', default=defStart,
                help='Which message number to start with.  Defaults to where the tool left off the last time, or zero.'),

    make_option('--smtpHost', dest='smtpHost', default=defSmtpHost,
                help='Hostname where SMTP server is running'),

    make_option('--smtpPort', type='int', dest='smtpPort', default=defSmtpPort,
                help='Port number to use for connecting to SMTP server'),
    ]

smtpPassword = None # implies using TLS
#---------------------------------------------------------------------------

def get_hwm(hwmfile):
    if not os.path.exists(hwmfile):
        return -1
    hwm = int(file(hwmfile).read())
    return hwm

def set_hwm(hwmfile, count):
    f = file(hwmfile, 'w')
    f.write(str(count))
    f.close()



def main(args):
    if sys.version_info < (2,5):
        print "Python 2.5 or better is required."
        sys.exit(1)

    # Parse the command line args
    parser = OptionParser(usage="%prog [options] mbox_file(s)",
                          description=__doc__,
                          version="%prog 0.9.1",
                          option_list=option_list)

    options, arguments = parser.parse_args(args)

    # ensure we have the required options
    if not options.toAddresses:
        parser.error('At least one To address is required (use --to)')

    if not options.fromAddress:
        parser.error('From address is required (use --from)')

    if not arguments:
        parser.error('At least one mbox file is required')

    # process the mbox file(s)
    for mboxfile in arguments:
        print "Opening %s..." % mboxfile
        mbox = mailbox.mbox(mboxfile)
        totalInMbox = len(mbox)
        print "Total messages in mbox: %d" % totalInMbox

        hwmfile = mboxfile + '.hwm'
        print 'Storing last message processed in %s' % hwmfile
        start = get_hwm(hwmfile)
        if options.start != -1:
            start = options.start
        start += 1
        print 'Starting with message #%d' % start

        totalSent = 0
        current = start

        # Outer loop continues until either the whole mbox or options.count
        # messages have been sent,
        while (current < totalInMbox and
               (totalSent < options.count or options.count == -1)):

            # Inner loop works one chunkSize number of messages at a time,
            # pausing and reconnecting to the SMTP server for each chunk.
            print 'Connecting to SMTP(%s, %d)' % (options.smtpHost, options.smtpPort)
            smtp = smtplib.SMTP(options.smtpHost, options.smtpPort)
            if smtpPassword: # use TLS
                smtp.ehlo()
                smtp.starttls()
                smtp.ehlo()
                smtp.login(options.fromAddress, smtpPassword)

            chunkSent = 0
            while chunkSent < options.chunkSize:
                msg = mbox[current]
                print 'Processing message %d: %s' % (current, msg['Subject'])

                # Here is where we actually send the message
                smtp.sendmail(options.fromAddress, options.toAddresses, msg.as_string())

                set_hwm(hwmfile, current)  # set new 'high water mark'
                current += 1
                totalSent += 1
                chunkSent += 1
                if (current >= totalInMbox or
                    (totalSent >= options.count and options.count != -1)):
                    break
            else:
                smtp.close()
                del smtp
                print "Pausing for %d seconds..." % options.chunkDelay,
                time.sleep(options.chunkDelay)
                print

    print 'Goodbye'

#---------------------------------------------------------------------------

if __name__ == '__main__':
    main(sys.argv[1:])
