#!/usr/bin/env python

"""
Extract all attachments from messages in mailbox, or file.

Attachments are stored in unique files within <directory> (default:
"."), using the names supplied in their headers, or, if not supplied,
(or the "--usefrom" flag is specified) the name
  YYYY_MM_DD.HH:MM:SS.<sender@site>.<number>[.<count>].<ext>
where the date is taken from the message header and <number> is the
attachment's order within the message.

Non-unique names generated above are made unique by appending
a count to that name (but preserving any extension).

NB: if you use the <file> form to modify messages in your active mailbox,
incoming mail during the process will be lost.

http://janeelix.com/piers/python/save_all_attachments
"""

Usage = """Usage: %s [--debug] [--delete] [--deletemsg] [--dir <directory>] \\
	[--match <regexp>] [--strip] [--stripmsg] [--usefrom] [--verbose] \\
	<file> | [--user <user>] <imap-server>

	--debug		output debugging details at <level>
	--delete	delete attachments from messages after saving
	--deletemsg	delete entire message after attachments extracted
	--dir		<directory> to hold extracted attachments [default: "."]
	--match		restrict debugging and/or warning messages to just
			those that match <regexp>
	--strip		delete attachments _without_ saving
			[neither of above work with <imap-server>]
	--stripmsg	delete messages containing attachments _without_ saving
	--verbose	show actions
	--usefrom	force names for attachments to use sender address
	--user		provide <user> for authentication on <imap-server>
			[default: invoker]
"""


import getopt, getpass, os, re, sys, time
import imaplib
import email, email.Errors, email.Header, email.Message, email.Utils


AttachDir = '.'
DebugLvl = 0
DebugMatch = None
DeleteAttachments = None	# Delete attachments from INBOX/file
DeleteMessages = None		# Delete entire message from INBOX/file
DeletedParts = 0		# Count of attachments deleted
ForceNameGen = 0		# Force default name generation
SaveAttachments = 1		# Save all attachments found
User = None			# IMAP4 user
Verbose = None


def usage(reason=''):
	sys.stdout.flush()
	if reason: sys.stderr.write('\t%s\n\n' % reason)
	head, tail = os.path.split(sys.argv[0])
	sys.stderr.write(Usage % tail)
	sys.stderr.write(__doc__)
	sys.exit(1)


def args():
	try:
		optlist, args = getopt.getopt(sys.argv[1:], '?',
			['debug=', 'delete', 'deletemsg', 'dir=', 'help',
			 'match', 'strip', 'stripmsg', 'usefrom', 'user=', 'verbose'])
	except getopt.error, val:
		usage(val)

	global AttachDir
	global DebugLvl
	global DebugMatch
	global DeleteAttachments
	global DeleteMessages
	global ForceNameGen
	global SaveAttachments
	global User
	global Verbose

	for opt,val in optlist:
		if opt == '--debug':
			DebugLvl = int(val)
			Verbose = 1
		elif opt == '--delete':
			DeleteAttachments = 1
		elif opt == '--deletemsg':
			DeleteMessages = 1
		elif opt == '--dir':
			AttachDir = val
		elif opt == '--strip':
			DeleteAttachments = 1
			SaveAttachments	= None
		elif opt == '--stripmsg':
			DeleteMessages = 1
			SaveAttachments	= None
		elif opt == '--match':
			DebugMatch = re.compile(val)
		elif opt == '--usefrom':
			ForceNameGen = 1
		elif opt == '--user':
			User = val
		elif opt == '--verbose':
			Verbose = 1
		else:
			usage()

	if len(args) != 1:
		usage()

	return args[0]


def gen_filename(name, part, addr, date, n):

	Debug(9, '''"name=%s, part-type=%s, n=%s" % (name, part.get_content_type(), n)''')
	if not name or ForceNameGen:
		if name:	# Check for '.tar.gz' etc
			name0, name1 = os.path.splitext(name)
			if len(name0) > 3 and name0[-4] == '.':
				ext = ''.join((os.path.splitext(name0)[1], name1))
			else:
				ext = name1
		else:
			ext = part.get_content_type() == 'text/plain' and '.txt' or '.xxx'
		pre = '%s.%s.%d' % (date, addr, n)
		file = ''.join((pre, ext))
	else:
		file = part.get_filename()
		# no need to decode
		#file = email.Header.decode_header(name)[0][0]
		#if email.Header.decode_header(file)[0][1] is not None:
		#	file = str(email.Header.decode_header(file)[0][0]).decode(email.Header.decode_header(file)[0][1])
		file = file.replace(' ', '_')

		if type(file) is not type('') and type(file) is not unicode:
			Debug(1, '''"name=%s" % `name`''')
			file = name
		file = os.path.basename(file)
		pre, ext = os.path.splitext(file)

	path = os.path.join(AttachDir, file)
	count = 1
	while os.access(path, os.F_OK):
		path = '%s.%s%s' % (os.path.join(AttachDir, pre), count, ext)
		count += 1

	Debug(9, '''"path=%s" % path''')
	return path


def walk_parts(msg, addr, date, dtime, count, msgnum):

	for part in msg.walk():

		if part.is_multipart():
			continue

		# --129.78.111.142.126.24561.1032609041.111.5183
		# Content-Type: image/jpeg; name=K-Woolyman-swimming.jpg
		# Content-Transfer-Encoding: base64
		# [Content-Disposition: attachment; filename="competition.ps"]

		dtypes = part.get_params(None, 'Content-Disposition')
		if not dtypes:
			if part.get_content_type() == 'text/plain':
				continue
			ctypes = part.get_params()
			Debug(3, '''"types=%s" % `ctypes`''')
			if not ctypes:
				continue
			for key,val in ctypes:
				if key.lower() == 'name':
					filename = gen_filename(val, part, addr, date, count)
					break
			else:
				continue
		else:
			Debug(3, '''"dtypes=%s" % `dtypes`''')
			attachment,filename = None,None
			for key,val in dtypes:
				key = key.lower()
				if key == 'filename':
					filename = val
				if key == 'attachment':
					attachment = 1
			if not attachment:
				continue
			filename = gen_filename(filename, part, addr, date, count)

		try:
			data = part.get_payload(decode=1)
		except:
			typ, val = sys.exc_info()[:2]
			warn("Message %s attachment decode error: %s for %s ``%s''"
				% (msgnum, str(val), part.get_content_type(), filename))
			continue

		if not data:
			warn("Could not decode attachment %s for %s"
				% (part.get_content_type(), filename))
			continue

		if type(data) is type(msg):
			count = walk_parts(data, addr, date, dtime, count, msgnum)
			continue

		Debug(1, '''"Found attachment %s for %s length %s" % (part.get_content_type(), filename, len(data))''')

		# skip embedded attachments
		is_attachment = dtypes is not None and ('attachment', '') in dtypes and not part.get_params(False, 'Content-ID')
		if SaveAttachments and is_attachment:
			if Verbose: print "Saving: %s" % filename
			try:
				# Open in binary mode (in case windoze)
				fd = open(filename, "wb")	# Bugfix: Mako Repo Nov 2003
				fd.write(data)
				fd.close()
			except IOError, val:
				error('Could not create "%s": %s' % (filename, str(val)))
			try:
				os.utime(filename, (dtime, dtime))
			except exc, val:
				warn('Could not set times for "%s": %s' % (filename, str(val)))

		if (DeleteAttachments and is_attachment) or DeleteMessages:
			if Verbose: print "Deleting: %s" % part.get_content_type()
			#part.set_payload('[DELETED]\n')
			part.set_payload('W0RFTEVURURdIA==\n')
			global DeletedParts; DeletedParts += 1

		count += 1

	return count


def process_message(text, msgnum):

	Debug(3, '''"Message %s, text %s" % (msgnum, text[:79])''')

	try:
		msg = email.message_from_string(text)
	except email.Errors.MessageError, val:
		warn("Message %s parse error: %s" % (msgnum, str(val)))
		return text

	date = msg['Date'] or 'Thu, 18 Sep 2002 12:02:27 +1000'
	dtime = email.Utils.parsedate_tz(date)
	date = time.strftime('%Y_%m_%d.%T', dtime[:9])
	dtime = email.Utils.mktime_tz(dtime)
	addr = email.Utils.parseaddr(msg['From'])[1]

	# custom code
	dotemail = open('%s/_email.txt' % AttachDir, 'w')
	dotemail.write("{0} -> {1}\n{2}\n".format(addr, email.Utils.parseaddr(msg['To'])[1], args()))
	dotemail.close()

	Debug(1, '''"Found message %s: %s" % (msgnum, addr)''')

	attachments_found = walk_parts(msg, addr, date, dtime, 0, msgnum)

	if attachments_found and DeleteMessages:
		if Verbose: print "Deleting message %s" % msgnum
		return ''

	if DeleteMessages or DeleteAttachments:
		#return msg.as_string(1)
		return msg.as_string()

	return None


def read_messages(fd):

	data = []; app = data.append

	for line in fd:
		if line[:5] == 'From ' and data:
			yield ''.join(data)
			data[:] = []
		app(line)

	if data:
		yield ''.join(data)


def process_file(name):

	fd = open(name)

	changed = []
	n = 0
	for message in read_messages(fd):
		changed.append(process_message(message, n))
		n += 1
	fd.close()

	if DeletedParts:
		try:
			fd = open(name, "w")
			fd.write('\n'.join(changed))
			fd.close()
		except IOError, val:
			error('Could not create "%s": %s' % (name, str(val)))


def process_server(host):

	global DeleteAttachments

	if DeleteAttachments:
		warn('IMAP attachment delete not implemented')
		DeleteAttachments = None

	try:
		mbox = imaplib.IMAP4(host)
	except:
		typ,val = sys.exc_info()[:2]
		error('Could not connect to IMAP server "%s": %s'
				% (host, str(val)))

	if User or mbox.state != 'AUTH':
		user = User or getpass.getuser()
		pasw = getpass.getpass("Please enter password for %s on %s: "
						% (user, host))
		try:
			typ,dat = mbox.login(user, pasw)
		except:
			typ,dat = sys.exc_info()[:2]

		if typ != 'OK':
			error('Could not open INBOX for "%s" on "%s": %s'
				% (user, host, str(dat)))

	mbox.select(readonly=(not DeleteMessages))
	typ, dat = mbox.search(None, 'ALL')

	deleteme = []
	for num in dat[0].split():
		typ, dat = mbox.fetch(num, '(RFC822)')
		if typ != 'OK':
			error(dat[-1])
		message = dat[0][1]
		if process_message(message, num) == '':
			deleteme.append(num)

	if deleteme:
		deleteme.sort()		# Must delete from end first
		deleteme.reverse()	# Otherwise 'num' is invalid
		for num in deleteme:
			mbox.store(num, 'FLAGS', '(\Deleted)')

	mbox.close()
	mbox.logout()


def Debug(lvl, str):

	if DebugLvl < lvl:
		return

	pad = ''

	#
	#	Delayed evaluation of debug() argument allowed
	#
	try:
		raise "get caller's frame"
	except:
		cf = sys.exc_info()[2].tb_frame.f_back
		try:
			pad = _frame_name(cf)
			if str:
				str = eval(str, cf.f_globals, cf.f_locals)
		except:
			if DebugLvl > 9:
				import traceback
				traceback.print_exc()
		del cf	# no circ. refs!

	warn("%-*s %s" % (35+lvl, pad, str))


def _frame_name(frm,  sep=os.sep):

	code = frm.f_code
	filename = code.co_filename
	filename = filename[filename.rfind(sep)+1:]	# `basename'
	self = frm.f_locals.get('self')
	if self is None:
		return '%s:%s' % (filename, code.co_name)
	return '%s:%s.%s' % (filename, self.__class__.__name__, code.co_name)


def warn(msg):

	if DebugMatch is not None and DebugMatch.search(msg) is None:
		return

	sys.stdout.flush()
	sys.stderr.write('%s\n' % msg)
	sys.stderr.flush()


def error(reason):
	sys.stderr.write('%s\n' % reason)
	sys.exit(1)


def main():

	file_or_server = args()

	if os.access(file_or_server, os.R_OK):
		process_file(file_or_server)
	else:
		process_server(file_or_server)


if __name__ == '__main__':
	try:
		main()
	except KeyboardInterrupt:
		pass
