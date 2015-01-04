/* msglint.c -- parse & quality check a message or DSN/MDN
 *
 * TODO:
 *  go through header registry
 *  HTTP/SIP support
 *  RFC 3261: message/sip
 *  RFC 2822 obsolete syntax
 *  RFC 3834: Auto-Submitted
 */

#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <ctype.h>
#include <time.h>
#include "imaildate.h"
#include "md5.h"

static const char version[] = "MIME Lint v1.04 2011-02-25";

int parsemessage(const char *, int);

static FILE *outfile;
#define NEWLINE "\n"

/* RFC references */
#define RFC_MIME_LB  "RFC 2046-4.1.1"
#define RFC_MIME_BD  "RFC 2046 pg 22"
#define RFC_MIME_DFS "RFC 2046 sec 5.2.1"
#define RFC_EXTB_CID "RFC 2046 sec 5.2.3"
#define RFC_MIME_XTY "RFC 2046 sec 6"
#define RFC_BAD8859  "RFC 2046 pg 10"
#define RFC_B64_LEN  "RFC 2045 pg 25"
#define RFC_QP_BAD   "RFC 2045 sec 6.7(1)"
#define RFC_QP_LEN   "RFC 2045 sec 6.7(5)"
#define RFC_MIXER    "RFC 2156"
#define RFC_DSN      "RFC 1891"
#define RFC_MDN      "RFC 2298"
#define RFC_CDISP_QS "RFC 2183 pg 3"
#define RFC_CDISP_FN "RFC 2046 sec 4.5.1, RFC 2183"
#define RFC_TOCCBCC  "RFC 822 sec 4.1"

/* text notice
 */
static const char text_para1[] =
   "%s is a strict syntax validator for Internet messages including "
   "MIME, RFC 822, DSN (" RFC_DSN ") and MDN (" RFC_MDN ") elements which "
   "has be run on the attached message.  The result follows:";
static const char text_para2[] = 
   "Output lines begin with 'OK:' for informational messages, "
   "'UNKNOWN:' for unregistered/unfamiliar extensions which may be incorrect, "
   "'WARNING:' for poor usage which is either "
   "likely to cause problems or fails the 'generate conservative protocol' "
   "principle, and 'ERROR:' for standards violations.  If your result "
   "contains only 'OK:' results, your message passed %s validation.";
static const char text_para3[] =
   "There is no guarantee that this validator is free of bugs itself, so feel "
   "free to contact <chris.newman@oracle.com> if you think you found an "
   "error in the validator or have a good idea to enhance the validator.";
static const char text_para4[] =
   "This free service for the Internet community.";

/* generic syntax:
 */
#define DATE_SYNTAX \
        "{O{Emon|tue|wed|thu|fri|sat|sun},W}{TD{OD}}W" \
        "{E:month|jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec}W" \
        "{TDDDD}W{TDD}:{TDD}{O:{TDD}}W" \
        "{A{T{A+|-}DDDD}|{Eut|gmt|est|edt|cst|cdt|mst|mdt|pst|pdt}{W3}}C"
static const char date_syntax[] = DATE_SYNTAX;
static const char date_new_syntax[] = \
        "{O{Emon|tue|wed|thu|fri|sat|sun},W}{TD{OD}}W" \
        "{E:month|jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec}W" \
        "{TDDDD}W{TDD}:{TDD}{O:{TDD}}W{A{T{A+|-}DDDD}|A{X3}}C";
#define MID_SYNTAX  "<L@D>C"
#define MBOX_PRESYNTAX "{A{OP}<{O@WD{*W,@WD}{W5}:}LW@WD>|LW@WD{C1}"
#define MBOX_SYNTAX MBOX_PRESYNTAX "}C"
#define GROUP_SYNTAX "P:W{O" MBOX_SYNTAX \
       "{*,W{*,W{W2}}" MBOX_SYNTAX "}};"
#define ADDRGP_SYNTAX MBOX_PRESYNTAX "|" GROUP_SYNTAX "}C"
static const char ALIST_SYNTAX[] = \
        "{A" ADDRGP_SYNTAX "{*,W{*,W{W2}}" \
        ADDRGP_SYNTAX "}|{Xat least one address required}}";
static const char MLIST_SYNTAX[] = \
        "{A" MBOX_SYNTAX "{*,F0W{*,W{W2}}" \
        MBOX_SYNTAX "}|{Xat least one mailbox required}}";
static const char RECEIVED_SYNTAX[] = \
        "C{*{E:item label|from:WD" \
        "{OW[{Xdomain-literal should be in comment}}|" \
        "by:WD|" \
        "with:W{E:'with' item|SMTP|ESMTP|ESMTPS|ESMTPA|ESMTPSA|LMTP|LMTPS|LMTPA|LMTPSA}|" \
        "id:W{A<L@D>|AW|{Xinvalid 'id' item}}|" \
        "via:W{E:'via' clause|UUCP}|" \
        "for:W{O<}LW{A@WD{O>}|{Xmissing domain in 'for' addr-spec}}|" \
        ":}C}{s;}W" DATE_SYNTAX;
#define URL_SYNTAX \
        "<{Ehttp:://{T{R1*:{AA|D}}{R1*:.{R1*:{AA|D}}}}/{S>}|" \
        "mailto::{O{AP<L@A>|L@A}{*,{AP<L@A>|L@A}}}{*?A=A}>|:" \
        "{T{*{AA|D|-}}}:{Uunknown/unwise URL type}{S>}}C"
static const char url_syntax[] = URL_SYNTAX;
static const char MTA_SYNTAX[] = \
        "{Edns:;WDC|" \
        "smtp:{W'dns' is preferable to 'smtp' as mta-name-type};WDC|" \
        ":{Uunknown MTA-type};W$}";
#define GENADDR_SYNTAX \
        "{Erfc822:;W{ALW@WD|" \
        "<LW@WD>{Wuse of '<' in rfc822 address-type discouraged}}" \
        "C|:{Uunknown address type};$}"
#define NEWSGROUP_SYNTAX \
        "{T{AL|D}{*{AL|D|+|-|_}}{R1*:.{AL|D}{*{AL|D|+|-|_}}}}"
static const char newslist_syntax[] = \
        NEWSGROUP_SYNTAX "{*," NEWSGROUP_SYNTAX "}W";
static const char type_syntax[] = \
      "{E:top-level content-type|multipart|text|application|"
      "image|audio|video|message|model}/A";
#define BUFSIZE 16384

/* header types:
 */
#define HEAD_MSG   0
#define HEAD_MIME  1
#define HEAD_DSN   2
#define HEAD_RCPT  3
#define HEAD_MDN   4
#define HEAD_INNER 5
#define HEAD_TEXT  6
#define HEAD_EXTB  7
#define HEAD_MTRKM 8
#define HEAD_MTRKR 9
static const char *headtypename[] = {
    "top-level message headers",
    "MIME headers",
    "Delivery Status Notification per-message fields",
    "Delivery Status Notification per-recipient fields",
    "Message Disposition Notification ('read receipt') fields",
    "headers of embedded message",
    "embedded headers",
    "external-body headers",
    "Message Tracking Status per-message fields",
    "Message Tracking Status per-recipient fields"
};

typedef enum toktype {
    tok_error,			/* illegal content */
    tok_special,
    tok_atom,
    tok_qstring,
    tok_dstring,
    tok_comment,
    tok_text
} toktype;
static const char *toktypemap[] = {
    "error",
    "special",
    "atom",
    "quoted-string",
    "domain-literal",
    "comment",
    "text"
};

typedef struct msgtoken {
    struct msgtoken *next;
    const char *data;
    toktype type;
    int len;
    int toknum;			/* token number in header */
    int lineno;			/* line number of header */
    int whiteafter;		/* set if whitespace follows token */
    int flags;			/* see below */
} msgtoken;
#define QSTRING_ATOM 0x0001 /* a qstring which contains only atom characters */

/* known headers
 */
typedef enum headtype {
    head_unknown=0,
    contenttype=1,
    contentdisp=2,
    contentte=3,
    returnpath=4,
    fromhead=5,
    lineshead=6,
    mischead=7
} headtype;
#define UNSTRUCTURED  0x00000000
#define STRUCTURED    0x00000001
#define TSPECIAL      0x00000002
#define HEADTYPE_MASK 0x00000003
#define SEMIEND       0x00000004  /* semi-colon ends structured field */
#define DUPOK         0x00000008  /* ignore duplicate headers */
#define DSN_OK        0x00000010
#define DSNRCPT_OK    0x00000020
#define MDN_OK        0x00000040
#define MSG_OK        0x00000080  /* DSN/MDN field ok in 822 headers */
#define MTRKM_OK      0x00000100  /* message track per-message */
#define MTRKR_OK      0x00000200  /* message track per-recipient */
#define HF_OK_MASK    0x000003f0
#define HF_ORIGRCPT   0x00000400  /* used for header block rule validation */
#define HF_ARRIVDATE  0x00000800
#define HF_REPORTMTA  0x00001000
#define HF_FINALRCPT  0x00002000
#define HF_ACTION     0x00004000
#define HF_STATUS     0x00008000
#define HF_FROM       0x00010000
#define HF_SUBJECT    0x00020000
#define HF_DATE       0x00040000
#define HF_CTYPE      0x00080000
#define HF_TO         0x00100000
#define HF_CC         0x00200000
#define HF_BCC        0x00400000
#define HF_SENDER     0x00800000
#define HF_CID        0x01000000
#define HF_RETURNPATH 0x02000000
#define HF_LINES      0x04000000
#define HF_NEWSGROUPS 0x08000000
#define HF_PATH       0x10000000
#define HF_MID        0x20000000
#define HF_ORIGENVID  0x40000000
#define HF_MASK       0x7ffffc00
struct headmap {
    const char *str;
    headtype type;
    const char *parse;
    int flags;
} known_headers[] = {
    /* RFC 822:
     *  date, from, to, subject, cc, bcc
     * RFC 1036:
     *  organization, references, newsgroups, followup-to, expires, path,
     *  lines
     * RFC 1766:
     *  content-language
     * RFC 1864:
     *  content-md5
     * RFC 1894 DSN per-message:
     *  original-envelope-id
     *  reporting-mta, dsn-gateway,
     *  received-from-mta, arrival-date
     * RFC 1894 DSN per-recipient:
     *  action, status, original-recipient, final-recipient, remote-mta
     *  diagnostic-code, last-attempt-date, will-retry-until
     * RFC 2045:
     *  content-type, content-transfer-encoding, content-id,
     *  content-description
     * RFC 2156 (MIXER; limited use):
     *  priority, importance, sensitivity
     * RFC 2183:
     *  content-disposition
     * RFC 2298 top-level:
     *  disposition-notification-to
     *  disposition-notification-options
     *  original-recipient
     * RFC 2298 MDN:
     *  disposition, reporting-ua, mdn-gateway, original-recipient,
     *  final-recipient, original-message-id, failure, error, warning
     * RFC 2369:
     *  list-help, list-subscribe, list-unsubscribe, list-post, list-owner,
     *  list-archive
     * RFC 2387:
     *  multipart/related
     * RFC 2424:
     *  content-duration
     * RFC 2852:
     *  Deliver-by-date
     * RFC 2919:
     *  List-id
     * RFC 3204:
     *  Content-disposition "signal"
     * RFC 3261:
     *  Content-disposition "alert", "icon", "render", "session"
     * RFC 3459:
     *  Content-disposition Handling parameter
     * RFC 3848:
     *  ESMTPA, ESMTPS, ESMTPSA, LMTPA, etc.
     * RFC 3886:
     *  message/tracking-status
     * RFC 3959:
     *  Content-disposition "early-session"
     * Non-standard:
     *  delivery-receipt-to, precedence, return-receipt-to, errors-to
     * -----------
     * Not checked (not seen yet and/or hard to validate):
     */
    "action",             mischead,
      "{E:delivery-status action|failed|delayed|delivered|relayed|expanded|"
      "transferred|opaque}C", /*NOTE: last two are for mtrk only */
                             MTRKR_OK | DSNRCPT_OK | STRUCTURED | HF_ACTION,
    "arrival-date",       mischead, date_new_syntax,
                                 MTRKM_OK | DSN_OK | STRUCTURED | HF_ARRIVDATE,
    "bcc",                mischead, ALIST_SYNTAX,    STRUCTURED | HF_BCC,
    "cc",                 mischead, ALIST_SYNTAX,    STRUCTURED | HF_CC,
    "content-description", mischead, NULL,           UNSTRUCTURED,
    "content-disposition", contentdisp,
      "{E:disposition|attachment|inline|signal|alert|icon|render|session|"
      "early-session}"
      "{*;W{E:disposition parameter|filename:F0=S|creation-date:=d|"
      "modification-date:=d|read-date:=d|size:=N|"
      "handling:={E:handling parameter|required|optional}|:=S}}C",
                                                     TSPECIAL,
    "content-duration",   mischead, "{T{R1*10:D}}C", TSPECIAL,
    "content-id",         mischead, MID_SYNTAX,      STRUCTURED | HF_CID,
    "content-length",     mischead, "NC{W6}",        STRUCTURED,
    "content-md5",        mischead, "K6AC",          STRUCTURED,
#define K_MD5     6
    "content-transfer-encoding", contentte,
      "{E:content-transfer-encoding|7bit:V1|8bit:V2|quoted-printable:V3|"
      "base64:V4}C", TSPECIAL,
    "content-type",    contenttype,
      "K0V9{E:top-level content-type|multipart:V1|text:V2|application:V3|"
      "image:V4|audio:V5|video:V6|message:V7|model:V8}/K1A"
      "{cparameter|O14|V1:M1|V1:K1=report:M2|V1:K1=signed:M3:M4|"
      "V1:K1=related:M5:O6:O7|V1:K1=encrypted:M3|V2:O8|V2:K1=plain:O9|V3:O8|"
      "V7:K1=external-body:M10:O11:O12:O13|:{*W;W"
      "{eA:parameter name|14:name:=F0S|1:boundary:=K2{t{R1*:B}}|"
      "2:report-type:=K3S|3:protocol:=K3Q|4:micalg:=S|5:type:=K3S|6:start:=S|"
      "7:start-type:=S|8:charset:=K4S|9:format:=K5S|"
      "10:access-type:={eS:access-type|ftp:f0:M14:M15:O16:O17|"
      "tftp:f0:M14:M15:O16:O17|anon-ftp:f0:M14:M15:O16:O17|"
      "local-file:f0:M14:O15|mail-server:M18:O19}|"
      "11:expiration:=S|12:size:=N|"
      "13:permission:={E:permission|read|read-write}|15:site:=S|"
      "16:directory:=S|17:mode:=S|18:server:=Q|19:subject:=S|::=S}}}",
                                                     TSPECIAL | HF_CTYPE,
#define K_CTYPE    0
#define K_SUBTYPE  1
#define K_BOUNDARY 2
#define K_RELTYPE  3            /* multipart/related */
#define K_REPTYPE  3		/* multipart/report */
#define K_PROTO    3		/* multipart/signed */
#define K_CHARSET  4
#define K_FORMAT   5
    "content-language",   mischead,
      "{T{R1*8:A}{*-{R1*8:A}}}{*,W{T{R1*8:A}{*-{R1*8:A}}}}C", TSPECIAL,
    "date",               mischead, date_syntax,     STRUCTURED | HF_DATE,
    "delivery-receipt-to", mischead,
      "LW@WDC{Wnon-standard header deprecated in favor of DSNs ("
      RFC_DSN ")}",                                  STRUCTURED,
    "deliver-by-date",    mischead, date_new_syntax, STRUCTURED | DSN_OK,  
    "diagnostic-code",    mischead,
      "{Esmtp|:{Uunknown diagnostic-code type}};WT",
	                                DSNRCPT_OK | STRUCTURED | SEMIEND,
    "disposition",        mischead,
      "{Emanual-action|automatic-action}/"
      "{EMDN-sent-manually|MDN-sent-automatically};W"
      "{Edisplayed|dispatched|processed|deleted|denied|failed}"
      "{O/{Eerror|warning|superseded|expired|mailbox-terminated}"
      "{*,{Eerror|warning|superseded|expired|mailbox-terminated}}}C",
                                                     TSPECIAL | MDN_OK,
    "disposition-notification-to", mischead, MLIST_SYNTAX, STRUCTURED,
    "dsn-gateway",        mischead, MTA_SYNTAX,      STRUCTURED | DSN_OK,
    "errors-to",          mischead, MBOX_SYNTAX 
      "{Wuse SMTP MAIL FROM/return-path instead of non-standard errors-to}",
	                                             STRUCTURED,
    "expires",            mischead, date_syntax,     STRUCTURED,
    "final-log-id",       mischead, NULL,            UNSTRUCTURED | DSNRCPT_OK,
    "final-recipient",    mischead, GENADDR_SYNTAX,
  	            MTRKR_OK | DSNRCPT_OK | MDN_OK | STRUCTURED | HF_FINALRCPT,
    "followup-to",        mischead, newslist_syntax, TSPECIAL,
    "from",               fromhead, MLIST_SYNTAX,    STRUCTURED | HF_FROM,
    "importance",         mischead, "{Elow|normal|high}C{W4}", STRUCTURED,
    "in-reply-to",        mischead,
      "{*{A" MID_SYNTAX "|P{Wold-style in-reply-to discouraged}}}C",
                                                     STRUCTURED,
    "last-attempt-date",  mischead, date_new_syntax,
	                                  MTRKR_OK | STRUCTURED | DSNRCPT_OK,
    "lines",             lineshead, "vC",            STRUCTURED | HF_LINES,
    "list-archive",       mischead, url_syntax,      TSPECIAL,
    "list-help",          mischead, url_syntax,      TSPECIAL,
    "list-id",            mischead, "P<D>C",         STRUCTURED,
    "list-owner",         mischead, url_syntax,      TSPECIAL,
    "list-post",          mischead, "{A{Eno}|" URL_SYNTAX "}C", TSPECIAL,
    "list-subscribe",     mischead, url_syntax,      TSPECIAL,
    "list-unsubscribe",   mischead, url_syntax,      TSPECIAL,
    "message-id",         mischead, MID_SYNTAX,      STRUCTURED | HF_MID,
    "mime-version",       mischead, "{T1.0}",        TSPECIAL,
    "newsgroups",         mischead, newslist_syntax, TSPECIAL | HF_NEWSGROUPS,
    "organization",       mischead, NULL,            UNSTRUCTURED,
    "original-envelope-id", mischead, NULL,
	          HF_ORIGENVID | DSN_OK | MTRKM_OK | UNSTRUCTURED,
    "original-message-id", mischead, MID_SYNTAX,     STRUCTURED | MDN_OK,
    "original-recipient", mischead, GENADDR_SYNTAX,
	   MTRKR_OK | DSNRCPT_OK | MDN_OK | MSG_OK | STRUCTURED | HF_ORIGRCPT,
    "path",               mischead, NULL,            UNSTRUCTURED | HF_PATH,
    "precedence",         mischead,
      "{E:precedence value|bulk|list|first-class|normal}{W6}", STRUCTURED,
    "priority",           mischead,
      "{Enormal|urgent|non-urgent|:"
      "{Xundefined priority value (see " RFC_MIXER ")}}C{W4}", STRUCTURED,
    "received",           mischead, RECEIVED_SYNTAX, STRUCTURED | DUPOK,
    "received-from-mta",  mischead, MTA_SYNTAX,      STRUCTURED | DSN_OK,
    "references",         mischead, "{1<L@D>W}C",    STRUCTURED,
    "remote-mta",         mischead, MTA_SYNTAX,
                                          MTRKR_OK | STRUCTURED | DSNRCPT_OK,
    "reporting-mta",      mischead, MTA_SYNTAX,
	                         MTRKM_OK | DSN_OK | STRUCTURED | HF_REPORTMTA,
    "reporting-ua",       mischead, NULL,          UNSTRUCTURED | MDN_OK,
    "reply-to",           mischead, ALIST_SYNTAX,    STRUCTURED,
    "resent-bcc",         mischead, ALIST_SYNTAX,    STRUCTURED | DUPOK,
    "resent-cc",          mischead, ALIST_SYNTAX,    STRUCTURED | DUPOK,
    "resent-date",        mischead, date_syntax,     STRUCTURED | DUPOK,
    "resent-from",        mischead, MLIST_SYNTAX,    STRUCTURED | DUPOK,
    "resent-message-id",  mischead, MID_SYNTAX,      STRUCTURED | DUPOK,
    "resent-originator-info", mischead, "A=S{*;WA=S}C", TSPECIAL | DUPOK,
    "resent-sender",      mischead, MBOX_SYNTAX,     STRUCTURED | DUPOK,
    "resent-to",          mischead, ALIST_SYNTAX,    STRUCTURED | DUPOK,
    "return-path",      returnpath, "<{OLF0@D}>C",   STRUCTURED | DUPOK
	                                           | HF_RETURNPATH,
    "return-receipt-to",  mischead,
      "LW@WDC{Wnon-standard header deprecated in favor of DSNs (" RFC_DSN ")}",
	                                             STRUCTURED,
    "sender",             mischead, MBOX_SYNTAX,     STRUCTURED | HF_SENDER,
    "sensitivity",        mischead,
      "{Epersonal|private|company-confidential}C{W4}", STRUCTURED,
    "status",             mischead, "{TD}.N.NC",
	                     MTRKR_OK | DSNRCPT_OK | STRUCTURED | HF_STATUS,
    "subject",            mischead, NULL,          UNSTRUCTURED | HF_SUBJECT,
    "to",                 mischead, ALIST_SYNTAX,    STRUCTURED | HF_TO,
    "will-retry-until",   mischead, date_new_syntax,
                                          MTRKR_OK | STRUCTURED | DSNRCPT_OK,
    "x-received",         mischead, RECEIVED_SYNTAX, STRUCTURED | DUPOK,
    "xref",               mischead, "AW{1" NEWSGROUP_SYNTAX ":NW}",
                                                     TSPECIAL,
    NULL, head_unknown, NULL, STRUCTURED
}, emptyhead = {NULL, head_unknown, NULL, 0};
#define DUPTABSIZE (sizeof (known_headers) / sizeof (struct headmap))

/* top-level content types
 *  verify content-type validator syntax matches these numbers
 */
typedef enum ctypeid {
    ct_unknown=0,
    multipart=1,
    text=2,
    application=3,
    image=4,
    audio=5,
    video=6,
    message=7,
    model=8
} ctypeid;

/* content transfer encodings
 *  verify content-transfer-encoding syntax above matches
 */
typedef enum cteid {
    cte_default=0,
    cte7bit=1,
    cte8bit=2,
    quoted_printable=3,
    base64=4
} cteid;

/* structure for whitespace warning context
 */
typedef struct whtwarn_ctx {
    msgtoken *cur, *last, *besttok;
    const char *curtype, *lasttype, *besttmpl;
    int curdphrase, lastdphrase;
} whtwarn_ctx;

/* structure to remember state of best parse
 */
typedef struct best_ctx {
    msgtoken *tok;
    const char *tmpl;
} best_ctx;

/* structure for stack-based token validator context
 */
typedef struct vstack {
    msgtoken *cur;
    const char *type;
    const char *vstate;
    const char *label;
    int count, llen;
    whtwarn_ctx wstate;
} vstack;

/* structure for stack-based character validator context
 */
typedef struct vcstack {
    const char *type;
    const char *tmpl;
    const char *data;
    int count, minc, maxc;
} vcstack;

/* debugging info for header
 */
typedef struct dbinfo {
    const char *headname;
    int startline, endline, headlen, flags;
} dbinfo;
#define DB_INDATE 0x0001
#define DB_INTYPE 0x0002

/* character set ids
 */
typedef enum charsetid {
    us_ascii = 0,
    utf7 = 1,
    utf8 = 2,
    iso8859_any = 3,
    koi8_r = 4,
    shift_jis = 5,
    iso2022_jp = 6,
    iso2022_cn = 7,
    cset_unknown
} charsetid;

/* enclosing MIME part info
 */
typedef struct MIMEinfo {
    msgtoken *keep[10];
    int indigest, inreport, inrelated, saw8bit, saw8char;
    int textplain, asciisubset, cset7bit;
    charsetid csetid;
    ctypeid typenum;
    cteid cte;
    struct MIMEinfo *next;
} MIMEinfo;

/* context for message parsing
 */
typedef struct msgcontext {
    MIMEinfo *mcur, *mpart;
    int lineno, lines, endhead;
    MD5_CTX md5;
} msgcontext;

/* information about header
 */
typedef struct headinfo {
    int flags, value;
} headinfo;
#define HEAD_PRESENT 0x0100

/* table for specials
 */
static const unsigned char specials[] = "()<>@,;:\\\".[]";
static const unsigned char tspecials[] = "()<>@,;:\\\"/[]?=";
static const unsigned char bspecials[] = "'()+_,-./:=? 0123456789";
static const unsigned char hexchars[] = "0123456789ABCDEF";
#define SPECIAL_BIT  0x01
#define TSPECIAL_BIT 0x02
#define BSPECIAL_BIT 0x04
static unsigned char special_table[256], hex_table[256];

const unsigned char cvt_to_lowercase[256] = {
    0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07,
    0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f,
    0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17,
    0x18, 0x19, 0x1a, 0x1b, 0x1c, 0x1d, 0x1e, 0x1f,
    0x20, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27,
    0x28, 0x29, 0x2a, 0x2b, 0x2c, 0x2d, 0x2e, 0x2f,
    0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37,
    0x38, 0x39, 0x3a, 0x3b, 0x3c, 0x3d, 0x3e, 0x3f,
    0x40,  'a',  'b',  'c',  'd',  'e',  'f',  'g',
     'h',  'i',  'j',  'k',  'l',  'm',  'n',  'o',
     'p',  'q',  'r',  's',  't',  'u',  'v',  'w',
     'x',  'y',  'z', 0x5b, 0x5c, 0x5d, 0x5e, 0x5f,
    0x60,  'a',  'b',  'c',  'd',  'e',  'f',  'g',
     'h',  'i',  'j',  'k',  'l',  'm',  'n',  'o',
     'p',  'q',  'r',  's',  't',  'u',  'v',  'w',
     'x',  'y',  'z', 0x7b, 0x7c, 0x7d, 0x7e, 0x7f,
    0x80, 0x81, 0x82, 0x83, 0x84, 0x85, 0x86, 0x87,
    0x88, 0x89, 0x8a, 0x8b, 0x8c, 0x8d, 0x8e, 0x8f,
    0x90, 0x91, 0x92, 0x93, 0x94, 0x95, 0x96, 0x97,
    0x98, 0x99, 0x9a, 0x9b, 0x9c, 0x9d, 0x9e, 0x9f,
    0xa0, 0xa1, 0xa2, 0xa3, 0xa4, 0xa5, 0xa6, 0xa7,
    0xa8, 0xa9, 0xaa, 0xab, 0xac, 0xad, 0xae, 0xaf,
    0xb0, 0xb1, 0xb2, 0xb3, 0xb4, 0xb5, 0xb6, 0xb7,
    0xb8, 0xb9, 0xba, 0xbb, 0xbc, 0xbd, 0xbe, 0xbf,
    0xc0, 0xc1, 0xc2, 0xc3, 0xc4, 0xc5, 0xc6, 0xc7,
    0xc8, 0xc9, 0xca, 0xcb, 0xcc, 0xcd, 0xce, 0xcf,
    0xd0, 0xd1, 0xd2, 0xd3, 0xd4, 0xd5, 0xd6, 0xd7,
    0xd8, 0xd9, 0xda, 0xdb, 0xdc, 0xdd, 0xde, 0xdf,
    0xe0, 0xe1, 0xe2, 0xe3, 0xe4, 0xe5, 0xe6, 0xe7,
    0xe8, 0xe9, 0xea, 0xeb, 0xec, 0xed, 0xee, 0xef,
    0xf0, 0xf1, 0xf2, 0xf3, 0xf4, 0xf5, 0xf6, 0xf7,
    0xf8, 0xf9, 0xfa, 0xfb, 0xfc, 0xfd, 0xfe, 0xff
};
#define TOLOWER(c) (cvt_to_lowercase[(unsigned char)(c)])

/*
 * Table for decoding base64
 */
#define XX 127
static const char decode64_table[256] = {
    XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
    XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
    XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,62, XX,XX,XX,63,
    52,53,54,55, 56,57,58,59, 60,61,XX,XX, XX,XX,XX,XX,
    XX, 0, 1, 2,  3, 4, 5, 6,  7, 8, 9,10, 11,12,13,14,
    15,16,17,18, 19,20,21,22, 23,24,25,XX, XX,XX,XX,XX,
    XX,26,27,28, 29,30,31,32, 33,34,35,36, 37,38,39,40,
    41,42,43,44, 45,46,47,48, 49,50,51,XX, XX,XX,XX,XX,
    XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
    XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
    XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
    XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
    XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
    XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
    XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
    XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
};
#define CHAR64(c)  (decode64_table[(unsigned char)(c)])

typedef struct base64ctx {
    int sawend, outlen;
    int tmplen;
    char tmpbuf[4];
    unsigned char badc;
} base64ctx;

/* a UTF8 lookup table */
#define EXT 0x20
#define BAD 0x40
static unsigned char utf8_table[256] = {
    /* 0x00 */ BAD,   1,   1,   1,   1,   1,   1,   1,
    /* 0x08 */   1,   1,   1,   1,   1,   1,   1,   1,
    /* 0x10 */   1,   1,   1,   1,   1,   1,   1,   1,
    /* 0x18 */   1,   1,   1,   1,   1,   1,   1,   1,
    /* 0x20 */   1,   1,   1,   1,   1,   1,   1,   1,
    /* 0x28 */   1,   1,   1,   1,   1,   1,   1,   1,
    /* 0x30 */   1,   1,   1,   1,   1,   1,   1,   1,
    /* 0x38 */   1,   1,   1,   1,   1,   1,   1,   1,
    /* 0x40 */   1,   1,   1,   1,   1,   1,   1,   1,
    /* 0x48 */   1,   1,   1,   1,   1,   1,   1,   1,
    /* 0x50 */   1,   1,   1,   1,   1,   1,   1,   1,
    /* 0x58 */   1,   1,   1,   1,   1,   1,   1,   1,
    /* 0x60 */   1,   1,   1,   1,   1,   1,   1,   1,
    /* 0x68 */   1,   1,   1,   1,   1,   1,   1,   1,
    /* 0x70 */   1,   1,   1,   1,   1,   1,   1,   1,
    /* 0x78 */   1,   1,   1,   1,   1,   1,   1,   1,
    /* 0x80 */ EXT, EXT, EXT, EXT, EXT, EXT, EXT, EXT,
    /* 0x88 */ EXT, EXT, EXT, EXT, EXT, EXT, EXT, EXT,
    /* 0x90 */ EXT, EXT, EXT, EXT, EXT, EXT, EXT, EXT,
    /* 0x98 */ EXT, EXT, EXT, EXT, EXT, EXT, EXT, EXT,
    /* 0xA0 */ EXT, EXT, EXT, EXT, EXT, EXT, EXT, EXT,
    /* 0xA8 */ EXT, EXT, EXT, EXT, EXT, EXT, EXT, EXT,
    /* 0xB0 */ EXT, EXT, EXT, EXT, EXT, EXT, EXT, EXT,
    /* 0xB8 */ EXT, EXT, EXT, EXT, EXT, EXT, EXT, EXT,
    /* 0xC0 */   2,   2,   2,   2,   2,   2,   2,   2,
    /* 0xC8 */   2,   2,   2,   2,   2,   2,   2,   2,
    /* 0xD0 */   2,   2,   2,   2,   2,   2,   2,   2,
    /* 0xD8 */   2,   2,   2,   2,   2,   2,   2,   2,
    /* 0xE0 */   3,   3,   3,   3,   3,   3,   3,   3,
    /* 0xE8 */   3,   3,   3,   3,   3,   3,   3,   3,
    /* 0xF0 */   4,   4,   4,   4,   4,   4,   4,   4,
    /* 0xF8 */ BAD, BAD, BAD, BAD, BAD, BAD, BAD, BAD
};

typedef struct utf8state {
    int state;			/* decoder state 0 = normal, > 0 in char */
    int value;			/* decoded value */
    int charsize;		/* size of character in bytes */
} utf8state;

/* free pool for tokenizer
 */
static msgtoken *msgfree = NULL;

/* command line option flags
 */
int verbose = 0;
int quiet = 0;
int silent = 0;
int mime_msg = 0;
int show_md5 = 0;
int web_cgi = 0;
int do_sendmail = 0;
static const char *reply_line, *from_addr = NULL;
static int reply_len;

/* strings for whitespace warnings
 */
static const char whitespace_str[] = "whitespace";
static const char comment_str[] = "comment";

/* message prefixes
 */
static const char w_none[]    = "";
static const char w_fatal[]   = "FATAL: ";
static const char w_error[]   = "ERROR: ";
static const char w_warn[]    = "WARNING: ";
static const char w_unknown[] = "UNKNOWN: ";
static const char w_ok[]      = "OK: ";
static const char pad_str[]   = "                    ";

/* do word-wrapping of a string
 *  str     -- string to wrap (pass NULL to flush word buffer)
 *  len     -- length of string
 *  indent  -- spaces at start of new line
 *  ppos    -- in/out column on display
 *  wbuf    -- word buffer
 *  buflen  -- length of word buffer
 *  bufused -- amount of word buffer that's in use
 */
static void wordwrap(const char *str, int len, int indent,
		     int *ppos, char *wbuf, int buflen, int *bufused)
{
    char *wptr = wbuf + *bufused;
    char *wend = wbuf + buflen - 1;
    const char *end = str + len;
    int pos = *ppos;

    /* loop over words */
    do {
	/* copy word to buffer */
	if (str != NULL) {
	    while (str < end && !isspace(*str) && wptr < wend) {
		*wptr = *str;
		++wptr, ++str;
	    }
	    if (str == end) break;
	}
	
	/* check if we need to word wrap
	 *  word wrap at 78 chars unless at beginning of line,
	 *  word wouldn't fit on new line or we're on the last word and it
	 *  will barely squeeze in under 80 columns
	 */
	if (pos > indent && wptr - wbuf + pos >= 78 &&
	    wptr - wbuf + indent < 80 &&
	    (str != NULL || wptr - wbuf + pos > 79)) {
	    fprintf(outfile, NEWLINE);
	    fprintf(outfile, "%.*s", indent, pad_str);
	    pos = indent;
	}
	pos += wptr - wbuf;

	/* deal with spaces */
	if (str != NULL) {
	    while (str < end && isspace(*str) && wptr < wend && pos < 78) {
		*wptr = *str;
		if (*str == '\n') {
		    pos = 78;
		    ++str;
		} else {
		    ++wptr, ++str, ++pos;
		}
	    }
	    while (str < end && isspace(*str)) ++str;
	}

	/* print it */
	*wptr = '\0';
	fprintf(outfile, "%s", wbuf);
	wptr = wbuf;

	/* check for end case */
	if (str == NULL) {
	    fprintf(outfile, NEWLINE);
	    break;
	}
    } while (str < end);
	
    /* set results */
    *ppos = pos;
    *bufused = wptr - wbuf;
}

/* Warning/error printf with line folding and different % options
 *  %s    NUL terminated string
 *  %.*s  integer length followed by data
 *  %d    decimal integer
 *  %u    unsigned
 *  %o    octal
 *  %x    hex
 *  %c    character, in quotes if printable, ^X or hex/octal
 *  %m    pointer to 16-character MD5 result, in hex
 *  %t    print contents of msgtoken
 *  %T    shortcut for "token '%t'"
 *  %%    literal '%'
 */
static void wprintf(dbinfo *db, const char *dt, const char *fmt, ...)
{
    static const char *lastfmt = NULL;
    static int numfmt = 0;
    const char *str;
    msgtoken *mtok = NULL;
    va_list pvar;
    char wbuf[256], pat[3], tmpstr[256], c;
    int indent, pad, pos, len, num, wused = 0;

    va_start(pvar, fmt);

    /* exit on silent mode, or too many repeats of previous error */
    if (silent || (lastfmt == fmt && ++numfmt > 2)) {
	va_end(pvar);
	return;
    }

    /* handle duplicate message suppression */
    if (lastfmt != fmt) {
	if (numfmt > 2) {
	    num = numfmt - 2;
	    numfmt = 0;
	    wprintf(NULL, w_warn,
		    "suppressed %d duplicate%s of previous WARNING",
		    num, num == 1 ? "" : "s");
	}
	lastfmt = dt == w_warn ? fmt : NULL;
	numfmt = 0;
    }

    /* do prefix */
    indent = pos = strlen(dt);
    fprintf(outfile, "%s", dt);

    /* loop between formatting characters */
    while (*fmt != '\0') {
	str = fmt;
	while (*fmt != '\0' && *fmt != '%')  ++fmt;
	wordwrap(str, fmt - str, indent, &pos, wbuf, sizeof (wbuf), &wused);
	if (*fmt == '\0') break;
	len = 0;
	pad = 0;
	switch (*++fmt) {
	  case '0': case '1': case '2': case '3': case '4':
	  case '5': case '6': case '7': case '8': case '9':
	    str = fmt - 1;
	    while (isdigit(*fmt)) {
		pad = pad * 10 + (*fmt - '0');
		++fmt;
	    }
	    len = fmt - str + 1;
	    if (*fmt != 's') break;
	    /* fall through */
	  case 's':
	    str = va_arg(pvar, char *);
	    len = strlen(str);
	    break;
	  case 'd':
	  case 'u':
	  case 'o':
	  case 'x':
	    num = va_arg(pvar, int);
	    pat[0] = '%';
	    pat[1] = *fmt;
	    pat[2] = '\0';
	    sprintf(tmpstr, pat, num);
	    len = strlen(tmpstr);
	    str = tmpstr;
	    break;
	  case 'm':
	    str = va_arg(pvar, char *);
	    for (len = 0; len < 16; ++len) {
		tmpstr[len*2]   = hexchars[(*(unsigned char *)(str+len))>>4];
		tmpstr[len*2+1] = hexchars[(*(unsigned char *)(str+len))&0xf];
	    }
	    str = tmpstr;
	    len = 32;
	    break;
	  case 'c':
	    c = va_arg(pvar, int);
	    if (c >= 0x20 && c < 0x7f) {
		sprintf(tmpstr, "'%c'", c);
	    } else if ((unsigned char) c < 0x20) {
		sprintf(tmpstr, "^%c", c + '@');
	    } else if (c == 0x7f) {
		strcpy(tmpstr, "^?");
	    } else {
		sprintf(tmpstr, "0%o, 0x%02x",
			(int) (unsigned char) c,
			(int) (unsigned char) c);
	    }
	    str = tmpstr;
	    len = strlen(tmpstr);
	    break;
	  case 't':
	  case 'T':
	    mtok = va_arg(pvar, msgtoken *);
	    if (mtok == NULL) {
		len = 0;
	    } else {
		len = mtok->len;
		str = mtok->data;
		if (*fmt == 'T') {
		    wordwrap("token '", 7, indent, &pos, wbuf, sizeof (wbuf),
			     &wused);
		}
	    }
	    break;
	  case '.':
	    if (fmt[1] == '*' && fmt[2] == 's') {
		len = va_arg(pvar, int);
		str = va_arg(pvar, char *);
		fmt += 2;
		break;
	    }
	    /* fall through */
	  default:
	    len = 2;
	    str = fmt - 1;
	    break;
	}
	if (pad) {
	    wordwrap(pad_str, pad - len, indent, &pos, wbuf, sizeof (wbuf),
		     &wused);
	}
	if (len) {
	    wordwrap(str, len, indent, &pos, wbuf, sizeof (wbuf), &wused);
	}
	if (*fmt == 'T' && mtok != NULL) {
	    wordwrap("'", 1, indent, &pos, wbuf, sizeof (wbuf), &wused);
	}
	++fmt;
    }

    /* handle debugging suffix */
    if (db != NULL) {
	str = (fmt[-1] == ' ') ? "" : " in ";
	if (db->headlen) {
	    sprintf(tmpstr, "%s%sheader '%.*s' at line", str,
		    db->flags & DB_INDATE ? "quoted date in " :
		    db->flags & DB_INTYPE ? "type parameter in " : "",
		    db->headlen, db->headname);
	} else {
	    sprintf(tmpstr, " at line");
	}
	len = strlen(tmpstr);
	if (db->endline > db->startline) {
	    sprintf(tmpstr + len, "s %d-%d", db->startline, db->endline);
	} else {
	    sprintf(tmpstr + len, " %d", db->endline);
	}
	len += strlen(tmpstr + len);
	wordwrap(tmpstr, len, indent, &pos, wbuf, sizeof (wbuf), &wused);
    }

    /* flush word buffer */
    wordwrap(NULL, 0, indent, &pos, wbuf, sizeof (wbuf), &wused);

    va_end(pvar);
}

/* base64 decode
 *  bctx   -- working context
 *  in     -- input data
 *  inlen  -- length of input data
 *  out    -- output data (may be same as in, may be NULL)
 *  outmax -- max length of output data if out non-NULL
 *
 * returns  1 if there is insufficient data or "leftovers"
 * returns  0 on success
 * returns -1 on bad base64 char
 * returns -2 on output buffer overflow
 * returns -3 on bad params
 * returns -4 on extraneous data
 */
int decode64(base64ctx *bctx, const char *in, int inlen,
	     char *out, int outmax)
{
    int infill, outfill;
    unsigned in0, in1, in2, in3;
    unsigned char *iptr, *end;
    unsigned char inbuf[4], outbuf[3];

    /* set up results */
    bctx->outlen = 0;
    bctx->badc = 0;
    
    /* check for invalid params, insufficient data */
    if (bctx->tmplen > 3) return (-3);
    if (inlen == 0 && (bctx->tmplen == 2 || bctx->tmplen == 3)) {
	while (bctx->tmplen < 4) {
	    bctx->tmpbuf[bctx->tmplen] = '=';
	    ++bctx->tmplen;
	}
    } else if (inlen + bctx->tmplen < 4) {
	memcpy(bctx->tmpbuf + bctx->tmplen, in, inlen);
	iptr = (unsigned char *) bctx->tmpbuf;
	end = iptr + bctx->tmplen + inlen;
	while (iptr < end) {
	    if (*iptr != '=' && CHAR64(*iptr) == XX) {
		bctx->badc = *iptr;
		return (-1);
	    }
	    ++iptr;
	}
	bctx->tmplen += inlen;
	return (1);
    }

    /* fill up initial input data buffer */
    infill = 4;
    if (bctx->tmplen > 0) {
	infill -= bctx->tmplen;
	memcpy(inbuf, bctx->tmpbuf, bctx->tmplen);
	bctx->tmplen = 0;
    }
    memcpy(inbuf + (4 - infill), in, infill);
    in += infill;
    inlen -= infill;

    for (;;) {
	/* check for end */
	if (bctx->sawend) return (-4);

	/* do decode/validation */
	if ((in0 = CHAR64(inbuf[0])) == XX) {
	    bctx->badc = inbuf[0];
	    return (-1);
	}
	if ((in1 = CHAR64(inbuf[1])) == XX) {
	    bctx->badc = inbuf[1];
	    bctx->tmpbuf[0] = inbuf[0];
	    bctx->tmplen = 1;
	    return (-1);
	}
	outbuf[0] = (in0 << 2) + (in1 >> 4);
	outfill = 3;
	if (inbuf[2] == '=' && inbuf[3] == '=') {
	    outbuf[1] = outbuf[2] = 0;
	    outfill = 1;
	    bctx->sawend = 1;
	} else if ((in2 = CHAR64(inbuf[2])) == XX) {
	    bctx->badc = inbuf[2];
	    bctx->tmpbuf[0] = inbuf[0];
	    bctx->tmpbuf[1] = inbuf[1];
	    bctx->tmplen = 2;
	    return (-1);
	} else {
	    outbuf[1] = (in1 << 4) | (in2 >> 2);
	    if (inbuf[3] == '=') {
		outbuf[2] = 0;
		outfill = 2;
		bctx->sawend = 1;
	    } else if ((in3 = CHAR64(inbuf[3])) == XX) {
		bctx->badc = inbuf[3];
		bctx->tmpbuf[0] = inbuf[0];
		bctx->tmpbuf[1] = inbuf[1];
		bctx->tmpbuf[2] = inbuf[2];
		bctx->tmplen = 3;
		return (-1);
	    } else {
		outbuf[2] = (in2 << 6) | in3;
	    }
	}

	/* process output buffer */
	if (out != NULL) {
	    if (outmax < outfill) return (-2);
	    memcpy(out, outbuf, outfill);
	    out += outfill;
	    outmax -= outfill;
	}
	bctx->outlen += outfill;

	/* fill input buffer */
	if (inlen < 4) break;
	memcpy(inbuf, in, 4);
	in += 4;
	inlen -= 4;
    }

    /* save remaining input buffer */
    if (inlen > 0) {
	memcpy(bctx->tmpbuf, in, inlen);
	bctx->tmplen = inlen;

	return (1);
    }

    return (0);
}

/* compare prefix with a token
 */
static int tokprefix(const char *prefix, int len, msgtoken *tok)
{
    if (len == -1) len = strlen(prefix);
    if (tok == NULL || tok->type == tok_error || tok->len < len) return (-1);

    return (strncasecmp(prefix, tok->data, len));
}

/* compare string with a token
 */
static int tokcomp(const char *instr, int len, msgtoken *tok)
{
    int tlen;
    const unsigned char *str = (const unsigned char *) instr;
    const unsigned char *tokstr;

    if (tok == NULL || tok->type == tok_error) return (-1);
    tlen = tok->len;
    tokstr = (const unsigned char *) tok->data;
    while (tlen > 0 || (len != 0 && *str != '\0')) {
	if (tlen == 0) return ((int) *str);
	if (len == 0 || *str == '\0') return (- (int) *tokstr);
	if (TOLOWER(*str) != TOLOWER(*tokstr))
	    return ((int) TOLOWER(*str) - TOLOWER(*tokstr));
	++str, ++tokstr, --len, --tlen;
    }
    
    return (0);
}

/* print a list of tokens
 */
static void tokprint(const char *label, msgtoken *cur)
{
    if (silent) return;
    for (; cur != NULL; cur = cur->next) {
	wprintf(NULL, label, " Token type %13s: %t",
		toktypemap[cur->type], cur);
    }
}

/* get a new message token
 */
static msgtoken *newmsgtoken(msgtoken ***ptr, toktype type,
			     const char *dat, int len, int toknum)
{
    msgtoken *result = msgfree;
    static const char uninit[] = "uninitialized token";
    
    if (result != NULL) {
	msgfree = result->next;
    } else {
	result = malloc(sizeof (msgtoken));
	if (result == NULL) {
	    perror("malloc");
	    exit(1);
	}
    }
    if (type == tok_error) {
	result->type = tok_error;
	result->data = uninit;
	result->len = sizeof (uninit) - 1;
    } else {
	result->type = type;
	result->data = dat;
	result->len = len;
    }
    result->whiteafter = 0;
    result->flags = 0;
    result->toknum = toknum;
    result->next = NULL;
    if (ptr != NULL) {
	**ptr = result;
	*ptr = &result->next;
    } 

    return (result);
}

/* dispose of MIME information
 */
static void disposeminfo(MIMEinfo *minfo)
{
    msgtoken *cur;
    int j;

    for (j = 0; j < 10; ++j) {
	if ((cur = minfo->keep[j]) != NULL) {
	    cur->next = msgfree;
	    msgfree = cur;
	}
    }
    free(minfo);
}

/* break a block of header data into tokens
 */
static msgtoken *tokenize(msgcontext *ctx, const char *dat, int len,
			  int flags, dbinfo *db)
{
    msgtoken *head, *last, **pcur;
    const char *start = dat;
    int clevel, spmask, tflags, toknum = 0;

    if ((flags & HEADTYPE_MASK) == UNSTRUCTURED) {
	head = NULL;
	pcur = &head;
	return (newmsgtoken(&pcur, tok_text, start, len, toknum++));
    }
    spmask = (flags & TSPECIAL) ? TSPECIAL_BIT : SPECIAL_BIT;
    head = last = NULL;
    pcur = &head;
    while (len > 0) {
	/* identify a comment */
	if (*dat == '(') {
	    if (dat != start) {
		last = newmsgtoken(&pcur, tok_atom, start, dat - start,
				   toknum++);
	    }
	    if (last != NULL) last->whiteafter |= 2;
	    start = dat;
	    clevel = 1;
	    ++dat, --len;
	    while (len > 0 && (*dat != ')' || --clevel > 0)) {
		if (*dat == '\\' && len > 1 &&
		    (dat[1] == '(' || dat[1] == ')')) {
		    wprintf(db, w_warn, "quoted comment delimiters unwise");
		    dat += 2, len -= 2;
		    continue;
	        }
		if (*dat == '(') {
		    wprintf(db, w_warn, "nested comments unwise");
		    ++clevel;
		} else if ((unsigned char) *dat > 127) {
		    wprintf(db, w_error, "8-bit");
		    if (ctx->mpart != NULL) {
		        ctx->mpart->saw8bit = 1;
		    }
		}
		++dat, --len;
	    }
	    if (len == 0) {
		wprintf(db, w_error, "unbalanced comment");
	    } else {
		++dat, --len;
	    }
	    newmsgtoken(&pcur, tok_comment, start, dat - start, toknum++);
	    start = dat;
	    continue;
	}

	/* identify a quoted-string */
	if (*dat == '"') {
	    if (dat != start) {
		last = newmsgtoken(&pcur, tok_atom, start, dat - start,
				   toknum++);
	    }
	    tflags = QSTRING_ATOM;
	    start = dat;
	    ++dat, --len;
	    while (len > 0 && *dat != '"') {
		if (*dat == '\\' && len > 1 && dat[1] == '"') {
		    dat += 2, len -= 2;
		    tflags = 0;
		} else {
		    if (tflags &&
			(special_table[(unsigned char) *dat] & spmask) != 0) {
			tflags = 0;
		    }
		    if (*dat == '\n' || *dat == '\r') {
			wprintf(db, w_warn, "newlines in quoted string don't "
			       "work well", db);
		    } else if ((unsigned char) *dat > 127) {
			wprintf(db, w_error, "8-bit", db);
		        if (ctx->mpart != NULL) {
		            ctx->mpart->saw8bit = 1;
		        }
		    }
		    ++dat, --len;
		}
	    }
	    if (tflags && dat - start - 1 > 78) tflags = 0;
	    last = newmsgtoken(&pcur, tok_qstring, start + 1, dat - start - 1,
			       toknum++);
	    last->flags = tflags;
	    if (len == 0) {
		wprintf(db, w_error, "unbalanced quote");
	    } else {
		++dat, --len;
	    }
	    start = dat;
	    continue;
	}

	/* identify a domain literal */
	if (*dat == '[') {
	    if (dat != start) {
		last = newmsgtoken(&pcur, tok_atom, start, dat - start,
				   toknum++);
	    }
	    start = dat;
	    ++dat, --len;
	    while (len > 0 && *dat != ']') {
		if (*dat == '\\' && len > 1 && dat[1] == ']') {
		    dat += 2;
		    len -= 2;
		    wprintf(db, w_warn, "quoted domain separators in domain "
			   "literal unwise");
		    continue;
		}
		if ((unsigned char) *dat >= 128) {
		    wprintf(db, w_error, "8-bit in domain literal %c", *dat);
		    if (ctx->mpart != NULL) {
		        ctx->mpart->saw8bit = 1;
		    }
		} else if (!isdigit(*dat) && *dat != '.') {
		    wprintf(db, w_warn, "unwise domain-literal char %d",
			    *dat);
		}
		++dat, --len;
	    }
	    if (len == 0) {
		wprintf(db, w_error, "unbalanced domain literal");
	    } else {
		++dat, --len;
	    }
	    last = newmsgtoken(&pcur, tok_dstring, start, dat - start,
			       toknum++);
	    start = dat;
	    continue;
	}

	/* handle specials */
	if (special_table[(unsigned char) *dat] & spmask) {
	    if (dat != start) {
		newmsgtoken(&pcur, tok_atom, start, dat - start, toknum++);
	    }
	    last = newmsgtoken(&pcur, tok_special, dat, 1, toknum++);
	    if (*dat == ';' && (flags & SEMIEND)) {
		++dat, --len;
		while (len > 0 &&
		       (dat[len - 1] == '\n' || dat[len - 1] == '\r')) {
		    --len;
		}
		newmsgtoken(&pcur, tok_text, dat, len, toknum++);
		return (head);
	    }
	    ++dat, --len;
	    start = dat;
	    continue;
	}

	/* handle whitespace */
	if (*dat == ' ' || *dat == '\t' || *dat == '\r' || *dat == '\n') {
	    if (dat != start) {
		last = newmsgtoken(&pcur, tok_atom, start, dat - start,
				   toknum++);
	    }
	    if (last != NULL) last->whiteafter |= 1;
	    ++dat, --len;
	    start = dat;
	    continue;
	}

	/* skip illegal characters */
	if (*dat < ' ' || (unsigned char) *dat > 126) {
	    if ((unsigned char) *dat >= 128 && ctx->mpart != NULL) {
	        ctx->mpart->saw8bit = 1;
	    }
	    if (dat != start) {
		last = newmsgtoken(&pcur, tok_atom, start, dat - start,
				   toknum++);
	    }
	    wprintf(db, w_error, "illegal syntax character %c", *dat);
	    while (len > 0 && (*dat < ' ' || (unsigned char) *dat > 126)) {
		++dat, --len;
	    }
	    start = dat;
	    continue;
	}

	/* it's an atom char, just advance */
	++dat, --len;
    }
    if (dat != start) {
	newmsgtoken(&pcur, tok_atom, start, dat - start, toknum++);
    }

    return (head);
}

/* skip to the end of a validator group
 */
static const char *skipvalgroup(const char *scan)
{
    int level = 0;

    while (*scan != '\0' && (*scan != '}' || level-- > 0)) {
	if (*scan == '{') ++level;
	++scan;
    }

    if (*scan == '}') return (scan + 1);

    return (scan);
}

/* skip to the end of a validator group segment
 */
static const char *skipvalseg(const char *scan)
{
    int level = 0;

    while (*scan != '\0' &&
	   (*scan != '|' || level > 0) &&
	   (*scan != '}' || level-- > 0)) {
	if (*scan == '{') ++level;
	++scan;
    }

    if (*scan == '|') return (scan + 1);

    return (scan);
}

/* try to reset validator state to avoid error
 */
static int valreset(int *pstack, vstack *vs, msgtoken **cur,
		    const char **tmpl, whtwarn_ctx *wht, best_ctx *best)
{
    int stack = *pstack;
    const char *next;

    /* remember best token */
    if (*cur == NULL ||
	(best->tok != NULL && (*cur)->toknum > best->tok->toknum)) {
	best->tok = *cur;
	best->tmpl = *tmpl;
    }

    /* try to back up */
    while (stack >= 0) {
	/* don't allow reset outside a matched enumerated type */
	if (*vs[stack].type == 'E' || *vs[stack].type == 'e') break;

	/* skip an optional, repeat or successful repeat-at-least-once */
	if (*vs[stack].type == 'O' || *vs[stack].type == '*' ||
	    (*vs[stack].type == '1' && vs[stack].count > 0)) {
	    *cur = vs[stack].cur;
	    *wht = vs[stack].wstate;
	    *tmpl = skipvalgroup(vs[stack].vstate);
	    *pstack = stack - 1;
	    return (1);
	}

	/* try a different alternate if available */
	if (*vs[stack].type == 'A') {
	    next = vs[stack].vstate = skipvalseg(vs[stack].vstate);
	    if (*next != '}' && *next != '\0') {
		*cur = vs[stack].cur;
		*wht = vs[stack].wstate;
		*tmpl = next;
		*pstack = stack;
		return (1);
	    }
	}
	--stack;
    }

    /* failed to reset */
    
    return (0);
}

/* update warning state
 */
static void warnupdate(whtwarn_ctx *wht, dbinfo *db)
{
    if (wht->lastdphrase) {
	wprintf(db, w_warn, "unquoted '.' in phrase unwise");
	wht->lastdphrase = 0;
    }
}

/* update whitespace state
 */
static void whtupdate(whtwarn_ctx *wht, msgtoken *cur, dbinfo *db)
{
    if (wht->last != NULL) {
	wprintf(db, w_warn, "%s after %T unwise", wht->lasttype,
	       wht->last);
    }
    warnupdate(wht, db);
    wht->lastdphrase = wht->curdphrase;
    wht->curdphrase = 0;
    wht->last = NULL;
    if (wht->cur != NULL) {
	wht->last = wht->cur;
	wht->lasttype = wht->curtype;
	wht->cur = NULL;
    }
    if (cur != NULL) {
	if (cur->whiteafter & 2) {
	    wht->cur = cur;
	    wht->curtype = comment_str;
	} else if (cur->whiteafter & 1) {
	    wht->cur = cur;
	    wht->curtype = whitespace_str;
	}
    }
    if (wht->last == wht->cur) {
	wht->last = NULL;
    }
}

/* reset character parsing state
 */
static int vcreset(int *pstack, vcstack *vs, const char **pdata,
	const char **ptmpl)
{
    int stack = *pstack;
    const char *next;

    while (stack >= 0) {
	if (*vs[stack].type == 'O' ||
	    *vs[stack].type == '*' ||
	    (*vs[stack].type == 'R' && vs[stack].count >= vs[stack].minc)) {
	    *ptmpl = skipvalgroup(vs[stack].tmpl);
	    *pdata = vs[stack].data;
	    *pstack = stack - 1;
	    return (1);
	}
	if (*vs[stack].type == 'A') {
	    next = vs[stack].tmpl = skipvalseg(vs[stack].tmpl);
	    if (*next != '}' && *next != '\0') {
		*ptmpl = next;
		*pdata = vs[stack].data;
		*pstack = stack;
		return (1);
	    }
	}
	--stack;
    }
    
    return (0);
}

/* validate a string of characters
 * template characters:
 *  A                        alpha
 *  B                        boundary char
 *  D                        digit
 *  L                        lowercase
 *  {O...}                   optional group of character syntax
 *  {R#1*#2:...}             repeat from #1 to #2 times, omit for defaults
 *  {Aalt1|alt2|...}         alternates syntax
 */
static void validatechars(const char **ptmpl, const char *data, int len,
			  int *olen, const char **pfailstr)
{
    const char *tmpl = *ptmpl;
    const char *start = data;
    const char *dend = data + len;
    int stack = -1;
    vcstack vs[10];

    *pfailstr = NULL;
    *olen = -1;
    for (;;) {
	switch (*tmpl) {
	  case '}':
	    if (stack < 0) {
		if (data == dend) goto DONE;
		*ptmpl = tmpl;
		*olen = data - start;
		return;
	    }
	    if (*vs[stack].type == '*' ||
		(*vs[stack].type == 'R' &&
		 (++vs[stack].count < vs[stack].maxc ||
		  vs[stack].maxc == 0))) {
		vs[stack].data = data;
		tmpl = vs[stack].tmpl;
		continue;
	    }
	    --stack;
	    ++tmpl;
	    continue;

	  case '|':
	    --stack;
	    tmpl = skipvalgroup(tmpl);
	    continue;
	    
	  case '{':
	    if (data == dend &&
		(tmpl[1] == 'O' || tmpl[1] == '*' ||
		 (tmpl[1] == 'R' && tmpl[2] == '*'))) {
		tmpl = skipvalgroup(tmpl + 1);
		continue;
	    }
	    break;
	}
	if (data == dend) {
	    if (vcreset(&stack, vs, &data, &tmpl)) continue;
	    break;
	}
	switch (*tmpl) {
	  default:		/* treat as literal */
	    if (*data != *tmpl) {
		if (vcreset(&stack, vs, &data, &tmpl)) continue;
		*pfailstr = ":expected character ";
		goto DONE;
	    }
	    break;

	  case 'A':
	    if (!isalpha(*data)) {
		if (vcreset(&stack, vs, &data, &tmpl)) continue;
		*pfailstr = "a letter";
		goto DONE;
	    }
	    break;

	  case 'L':
	    if (!islower(*data)) {
		if (vcreset(&stack, vs, &data, &tmpl)) continue;
		*pfailstr = "a lowercase letter";
		goto DONE;
	    }
	    break;

	  case 'D':
	    if (!isdigit(*data)) {
		if (vcreset(&stack, vs, &data, &tmpl)) continue;
		*pfailstr = "a digit";
		goto DONE;
	    }
	    break;

	  case 'B':
	    if ((special_table[(unsigned char) *data] & BSPECIAL_BIT) == 0) {
		if (vcreset(&stack, vs, &data, &tmpl)) continue;
		*pfailstr = "a boundary char (" RFC_MIME_BD ")";
		goto DONE;
	    }
	    break;

	  case '{':
	    ++tmpl;
	    ++stack;
	    vs[stack].type = tmpl;
	    vs[stack].tmpl = tmpl + 1;
	    vs[stack].data = data;
	    vs[stack].minc = 0;
	    vs[stack].maxc = 0;
	    vs[stack].count = 0;
	    switch (*tmpl) {
	      default:
		*ptmpl = tmpl;
		return;

	      case 'A':
	      case 'O':
	      case '*':
		++tmpl;
		continue;

	      case 'R':
		++tmpl;
		if (*tmpl == '0') { /* don't allow leading '0' */
		    *ptmpl = tmpl;
		    return;
		}
		while (isdigit(*tmpl)) {
		    vs[stack].minc = 10 * vs[stack].minc + (*tmpl++ - '0');
		}
		if (*tmpl != '*') {
		    *ptmpl = tmpl;
		    return;
		}
		++tmpl;
		while (isdigit(*tmpl)) {
		    vs[stack].maxc = 10 * vs[stack].maxc + (*tmpl++ - '0');
		}
		if (*tmpl != ':') {
		    *ptmpl = tmpl;
		    return;
		}
		vs[stack].tmpl = ++tmpl;
		continue;
	    }
	    break;
	}
	++tmpl;
	++data;
    }
    /* skip over any optional elements of template */
    if (*tmpl == '{' && tmpl[1] == 'O') tmpl = skipvalgroup(tmpl + 1);
  DONE:
    *ptmpl = tmpl;
    *olen = data - start;
}

/* validate a tokenized header
 *  A       arbitary atom
 *  C       allow comments and whitespace without a warning
 *  D       domain
 *  d       quoted date-time
 *  F#[:]   set header flag number
 *  f#[:]   clear header flag number
 *  I       signed integer
 *  K#[:]   keep next token in MIMEinfo keep slot 0-9
 *  L       local part
 *  M#[:]   set mandatory flag
 *  n       no-op
 *  N       number
 *  O#[:]   set optional flag
 *  P       phrase
 *  Q       arbitary quoted-string
 *  S       string token (atom or quoted-string)
 *  T       text token
 *  V#      set header value number 0-9
 *  W       allow whitespace without a warning
 *  [       domain literal
 *  {|}     groupings:
 *   {O...}                        optional grouping
 *   {*...}                        repeating zero or more times
 *   {1...}                        repeating, present at least once
 *   {Aalt1|alt2...}               alternates grouping
 *   {Ctext}                       Print warning if comment seen
 *   {clabel|cond:cond|:syntax}    conditionalized syntax eval (see "{e...}")
 *           R                     reset state
 *           V#                    check against value (from V#)
 *           K#=text               check against kept string (from K#)
 *           M#                    set mandatory flag #
 *           O#                    set optional flag #
 *   {Etype:syntax|type:syntax...} enumerated type list
 *   {E:label|type:syntax...}      labelled enumerated type list
 *   {eC:label|cond:type:syntax...} conditionalized labelled enum type list
 *                                 C == A,Q,S
 *   {Q...}                        quoted-string with sub-syntax (like {T...})
 *   {Stoken}                      skip to token
 *   {stoken}                      skip to token on error
 *   {T...}                        atom with sub-syntax see validatechars
 *   {t...}                        atom/quoted-string with sub-syntax
 *   {Wtext}                       print a warning message
 *   {Utext}                       print an unknown token message
 *   {Xtext}                       print an error message
 *  $       end parse
 *  .@:;<>=,/\?  literal specials
 */
static void validatehead(msgcontext *ctx, const char *tmpl,
			 msgtoken *cur, headinfo *hinfo,
			 struct headmap *hmap, dbinfo *db)
{
    static const char enumtype[] = "enumerated type";
    msgtoken *lasttok, *subtok, **mkeep;
    const char *tokend, *failstr, *scan, *label;
    int j, llen, stack = -1, success, cond_enum;
    unsigned long callow, creq, cseen;
    const char *reqmap[32];
    int reqlen[32];
    vstack vs[10];
    whtwarn_ctx wht;
    best_ctx best;

    memset(reqmap, 0, sizeof (reqmap));
    memset(reqlen, 0, sizeof (reqlen));
    memset(&wht, 0, sizeof (wht));
    best.tok = cur;
    best.tmpl = tmpl;
    callow = creq = cseen = 0;
    while (*tmpl != '\0') {
	/* handle syntacic elements of template: */
	switch (*tmpl) {
	  case 'C':
	    while (cur != NULL && cur->type == tok_comment) cur = cur->next;
	    /* fall through */
	  case 'W':
	    /* ignore whitespace warnings */
	    if (wht.curtype == whitespace_str || *tmpl == 'C') {
		wht.cur = NULL;
	    }
	    ++tmpl;
	    continue;
	    
	  case 'F':
	  case 'f':
	  case 'K':
	  case 'M':
	  case 'O':
	    label = tmpl;
	    ++tmpl;
	    if (!isdigit(*tmpl)) {
	        wprintf(db, w_fatal, "%c flag must be followed by digit",
			*tmpl);
	        exit(1);
	    }
	    j = 0;
	    while (isdigit(*tmpl)) {
		j = j * 10 + (*tmpl - '0');
		++tmpl;
	    }
	    if (*tmpl == ':') ++tmpl;
	    if (*label == 'F') {
		hinfo->flags |= 1UL << j;
		continue;
	    }
	    if (*label == 'f') {
		hinfo->flags &= ~(1UL << j);
		continue;
	    }
	    if (*label == 'K') {
		if (j > 9) {
		    wprintf(db, w_fatal, "Keep value %d out of range in "
			    "template", j);
		    exit(1);
		}
		while (cur != NULL && cur->type == tok_comment) {
		    cur = cur->next;
		}
		if (cur != NULL) {
		    cur->lineno = ctx->lineno;
		    mkeep = ctx->mcur->keep + j;
		    if (*mkeep != NULL) {
			wprintf(db, w_error, "duplicate param '%t'", cur);
		    }
		    *mkeep = cur;
		}
		continue;
	    }
	    if (j) {
		callow |= 1UL << (j - 1);
		if (*label == 'M') {
		    creq |= 1UL << (j - 1);
		}
	    }
	    continue;

	  case 'V':
	    if (!isdigit(tmpl[1])) {
	        wprintf(db, w_fatal, "V flag must be followed by digit");
	        exit(1);
	    }
	    hinfo->value = tmpl[1] - '0';
	    tmpl += 2;
	    continue;

	  case 'n':		/* no-op, good for debugger breakpoints */
	    ++tmpl;
	    continue;

	  case '{':
	    /* handle warnings and errors */
	    if (tmpl[1] == 'W' || tmpl[1] == 'U' || tmpl[1] == 'X' ||
		tmpl[1] == 'C') {
		tokend = skipvalgroup(tmpl + 1);
		if (tmpl[1] != 'C' ||
		    (cur != NULL && cur->type == tok_comment)) {
		    if (isdigit(tmpl[2])) {
			switch (atoi(tmpl + 2)) {
			  default:
			    failstr = "unknown error code in template";
			    break;
			  case 1:
			    failstr = "The address form "
				"'display-name <addr@domain>' is preferred to "
				"'addr@domain (comment)'";
			    break;
			  case 2:
			    failstr = "extra comma unwise";
			    break;
			  case 3:
			    failstr = "old-style timezone in date";
			    break;
			  case 4:
			    failstr = "header standardized only for use by "
				"X.400/MIME gateways (" RFC_MIXER ")";
			    break;
			  case 5:
			    failstr = "old-style route-addr";
			    break;
			  case 6:
			    failstr = "use of non-standard header unwise";
			    break;
			}
			j = strlen(failstr);
		    } else {
			failstr = tmpl + 2;
			j = tokend - tmpl - 3;
		    }
		    wprintf(db, tmpl[1] == 'X' ? w_error :
			    (tmpl[1] == 'U' ? w_unknown : w_warn),
			    "%.*s%s%T", j, failstr,
			    cur ? " at or before " : "", cur);
		}
		tmpl = tokend;
		continue;
	    }
	    /* if at end of parse and we see an optional group, skip it */
	    if (cur == NULL && (tmpl[1] == 'O' || tmpl[1] == '*')) {
		tmpl = skipvalgroup(tmpl + 1);
		continue;
	    }
	    break;

	  case '}':
	    if (stack < 0) {
		wprintf(db, w_fatal, "extra '}' at template '%s'", tmpl);
		exit(1);
	    }
	    /* process repeating groups or pop the group stack */
	    if (*vs[stack].type == '1' || *vs[stack].type == '*') {
		++vs[stack].count;
		vs[stack].cur = cur;
		vs[stack].wstate = wht;
		tmpl = vs[stack].vstate;
		continue;
	    }
	    /* process conditional eval */
	    if (*vs[stack].type == 'c') {
		for (j = 0; j < 31; ++j) {
		    if ((creq & (1UL << j)) != 0 &&
			(cseen & (1UL << j)) == 0) {
			if (reqlen[j] != 0) {
			    wprintf(db, w_error, "Missing mandatory %.*s "
				    "'%.*s'", vs[stack].llen, vs[stack].label,
				    reqlen[j], reqmap[j]);
			} else {
			    wprintf(db, w_error, "Missing mandatory %.*s",
				    vs[stack].llen, vs[stack].label);
			    break;
			}
		    } else if ((callow & (1UL << j)) == 0 &&
			       (cseen & (1UL << j)) != 0 &&
			       reqlen[j] != 0) {
			wprintf(db, w_warn, "Unexpected %.*s '%.*s'",
				vs[stack].llen, vs[stack].label,
				reqlen[j], reqmap[j]);
		    }
		}
	    }
	    --stack;
	    ++tmpl;
	    continue;

	  case '|':
	    /* hit end of alternative; pop the group stack */
	    --stack;
	    tmpl = skipvalgroup(tmpl);
	    continue;
	}

	/* skip comments */
	while (cur != NULL && cur->type == tok_comment) cur = cur->next;

	/* update whitespace warning state, except when starting
	 * a new structural group.
	 */
	if (*tmpl != '{' || tmpl[1] == 'E' || tmpl[1] == 'e' ||
	    tmpl[1] == 'T' || tmpl[1] == 't' || tmpl[1] == 'Q' ||
	    tmpl[1] == 'S' || tmpl[1] == 's') {
	    whtupdate(&wht, cur, db);
	} else {
	    warnupdate(&wht, db);
	}
	
	/* validate current token */
	if (cur == NULL && (*tmpl != '{' || tmpl[1] != 'c')) {
	  MISSINGTOK:
	    if (valreset(&stack, vs, &cur, &tmpl, &wht, &best)) continue;
	    wprintf(db, w_error, "missing tokens '%s' at end of ", tmpl);
	    return;
	}

	/* process template */
	switch (*tmpl) {
	  case 'v':		/* save numeric-value */
	    hinfo->value = 0;
	    tokend = cur->data + cur->len;
	    for (scan = cur->data; isdigit(*scan) && scan < tokend; ++scan) {
		hinfo->value = hinfo->value * 10 + (*scan - '0');
	    }
	    if (scan != tokend || cur->type != tok_atom) {
		if (valreset(&stack, vs, &cur, &tmpl, &wht, &best)) continue;
		wprintf(db, w_error, "%T should be a%s number",
			cur, j < 0 ? "n unquoted" : "");
	    }
	    cur = cur->next;
	    break;
	    
	  case 'N':
	    j = cur->len;
	    while (--j >= 0 && isdigit(cur->data[j]))
		;
	    if (j >= 0 || cur->type != tok_atom) {
		if (valreset(&stack, vs, &cur, &tmpl, &wht, &best)) continue;
		wprintf(db, w_error, "%T should be a%s number",
			cur, j < 0 ? "n unquoted" : "");
	    }
	    cur = cur->next;
	    break;

	  case 'I':
	    j = cur->len;
	    while (--j > 0 && isdigit(cur->data[j]))
		;
	    if (j == 0 && (*cur->data == '-' || *cur->data == '+' ||
			   isdigit(*cur->data))) {
		--j;
	    }
	    if (j >= 0 || cur->type != tok_atom) {
		if (valreset(&stack, vs, &cur, &tmpl, &wht, &best)) continue;
		wprintf(db, w_error, "%T should be an integer", cur);
	    }
	    cur = cur->next;
	    break;

	  case 'A':
	    if (cur->type != tok_atom) {
		if (valreset(&stack, vs, &cur, &tmpl, &wht, &best)) continue;
		wprintf(db, w_error, "%T should be an atom", cur);
		if (cur->type == tok_special && *cur->data != '.') break;
	    }
	    cur = cur->next;
	    break;

	  case 'Q':
	    if (cur->type != tok_qstring) {
		if (valreset(&stack, vs, &cur, &tmpl, &wht, &best)) continue;
		wprintf(db, w_error, "%T should be a quoted-string",
			cur);
		if (cur->type == tok_special && *cur->data != '.') break;
	    }
	    cur = cur->next;
	    break;

	  case 'd':
	    if (cur->type != tok_qstring) {
		if (valreset(&stack, vs, &cur, &tmpl, &wht, &best)) continue;
		wprintf(db, w_error, "%T should be a quoted date-time", cur);
		if (cur->type == tok_special && *cur->data != '.') break;
	    } else {
		/* re-tokenize quoted-string as a date, validate, and dump
		 * result on free list
		 */
		subtok = tokenize(ctx, cur->data, cur->len, STRUCTURED, db);
		db->flags |= DB_INDATE;
		validatehead(ctx, date_new_syntax, subtok, hinfo, hmap, db);
		db->flags &= ~DB_INDATE;
		if (subtok != NULL) {
		    for (lasttok = subtok; lasttok->next != NULL;
			 lasttok = lasttok->next)
			;
		    lasttok->next = msgfree;
		    msgfree = subtok;
		}
	    }
	    cur = cur->next;
	    break;

	  case 'S':
	    if (cur->type != tok_qstring && cur->type != tok_atom) {
		if (valreset(&stack, vs, &cur, &tmpl, &wht, &best)) continue;
		wprintf(db, w_error, "%T should be an atom or "
			"quoted-string", cur);
		if (cur->type == tok_special && *cur->data != '.') break;
	    } else if (cur->type == tok_qstring &&
		       hmap->type == contentdisp &&
		       (cur->flags & QSTRING_ATOM)) {
		wprintf(db, w_warn, "quoted-string \"%t\" SHOULD be an "
			"atom (" RFC_CDISP_QS ")", cur);
	    }
	    cur = cur->next;
	    break;

	  case '[':
	    if (cur->type != tok_dstring) {
		if (valreset(&stack, vs, &cur, &tmpl, &wht, &best)) continue;
		wprintf(db, w_error, "%T should be a domain literal", cur);
		if (cur->type == tok_special && *cur->data != '.') break;
	    }
	    cur = cur->next;
	    break;

	  case 'D':		/* parse a domain */
	    if (cur->type == tok_dstring) {
		cur = cur->next;
		break;
	    }
	    j = 0;
	    lasttok = cur;
	    for (;;) {
		if (cur == NULL || cur->type != tok_atom) {
		    if (valreset(&stack, vs, &cur, &tmpl, &wht, &best)) break;
		    wprintf(db, w_error, "%T%s should be an atom%s",
			    cur, cur ? " " : "",
			    j ? "" : " or a domain literal");
		    /* don't advance over specials other than '.' */
		    if (cur != NULL &&
			(cur->type != tok_special || *cur->data == '.')) {
			if (j) whtupdate(&wht, cur, db);
			cur = cur->next;
		    } else {
			cur = lasttok;
		    }
		    ++tmpl;
		    break;
		}
		if (j) whtupdate(&wht, cur, db);
		tokend = cur->data + cur->len;
		for (scan = cur->data; scan < tokend &&
		     (isalnum(*scan) || *scan == '-'); ++scan)
		    ;
		if (scan < tokend) {
		    wprintf(db, w_warn, "unexpected domain character %c"
			   " found in %T", *scan, cur);
		}
		lasttok = cur;
		cur = cur->next;
		while (cur != NULL && cur->type == tok_comment) {
		    cur = cur->next;
		}
		if (cur == NULL || cur->type != tok_special ||
		    *cur->data != '.') {
		    if (!j) {
			wprintf(db, w_warn, "short-form domain '%t' unwise",
			       lasttok);
		    }
		    cur = lasttok->next;
		    ++tmpl;
		    break;
		}
		whtupdate(&wht, cur, db);
		lasttok = cur = cur->next;
		while (cur != NULL && cur->type == tok_comment) {
		    cur = cur->next;
		}
		++j;
	    }
	    continue;

	  case 'T':
	    if (cur->type != tok_text) {
		if (valreset(&stack, vs, &cur, &tmpl, &wht, &best)) continue;
		wprintf(db, w_error, "%T should be text", cur);
	    }
	    cur = cur->next;
	    break;

	  case 'L':		/* local-part */
	  RETRY_LOCAL_PART:
	    j = 0;
	    if (cur->type == tok_qstring) {
		for (j = 0; j < cur->len && cur->data[j] > ' ' &&
		     cur->data[j] < 127 &&
		     (cur->data[j] == '.' ||
		      (special_table[(unsigned char) cur->data[j]]
		       & SPECIAL_BIT) == 0); ++j)
		    ;
		if (j == cur->len) {
		    wprintf(db, w_warn, "quotes around local-part \"%t\" "
			    "unnecessary", cur);
		}
		cur = cur->next;
		j = 1;
	    } else if (cur->type == tok_atom) {
		cur = cur->next;
		while (cur != NULL && cur->type == tok_special &&
		       *cur->data == '.' && cur->next != NULL &&
		       cur->next->type == tok_atom) {
		    whtupdate(&wht, cur, db);
		    whtupdate(&wht, cur->next, db);
		    cur = cur->next->next;
		}
	    } else {
		if (valreset(&stack, vs, &cur, &tmpl, &wht, &best)) continue;
		wprintf(db, w_error, "expected atom or quoted-string at '%t'",
			cur);
		/* if it's a '<' it probably didn't belong; skip it an
		 * try again.  If it's a '.' handle it.  Otherwise skip it
		 * and go on to next production.
		 */
		if (cur->type == tok_special && *cur->data == '<') {
		    if ((cur = cur->next) != NULL) goto RETRY_LOCAL_PART;
		    break;
		}
		if (cur->type != tok_special || *cur->data != '.') {
		    cur = cur->next;
		    break;
		}
	    }
	    while (cur != NULL && cur->type == tok_comment) cur = cur->next;
	    while (cur != NULL &&
		   (cur->type == tok_special && *cur->data == '.')) {
		if (j == 1) {
		    wprintf(db, w_warn, "local-part with quoted-string and "
			    "'.' unwise");
		    j = 2;
		}
		if (cur->type == tok_special) {
		    whtupdate(&wht, cur, db);
		    cur = cur->next;
		    while (cur != NULL && cur->type == tok_comment) {
			cur = cur->next;
		    }
		}
		if (cur == NULL) goto MISSINGTOK;
		if (j == 0 && cur->type == tok_qstring) {
		    wprintf(db, w_warn, "local-part with atom and "
			    "quoted-string unwise");
		    j = 2;
		}
		if (cur->type != tok_atom && cur->type != tok_qstring) {
		    j = 3;
		    break;
		}
		whtupdate(&wht, cur, db);
		cur = cur->next;
		while (cur != NULL && cur->type == tok_comment) {
		    cur = cur->next;
		}
	    }
	    if (j == 3) {
		if (valreset(&stack, vs, &cur, &tmpl, &wht, &best)) continue;
		wprintf(db, w_error, "expected atom or quoted-string at '%t'",
			cur);
		if (cur->type != tok_special || *cur->data != '@') {
		    cur = cur->next;
		}
	    }
	    break;

	  case 'P':		/* phrase */
	    wht.cur = NULL;
	    j = 0;
	    while (cur != NULL &&
		   (cur->type == tok_qstring || cur->type == tok_comment ||
		    cur->type == tok_atom ||
		    (cur->type == tok_special && *cur->data == '.'))) {
		if (cur->type == tok_special) {
		    wht.curdphrase = 1;
		}
		cur = cur->next;
		++j;
	    }
	    if (j == 0) {
		if (valreset(&stack, vs, &cur, &tmpl, &wht, &best)) continue;
		wprintf(db, w_error, "expected phrase at %T", cur);
	    }
	    break;

	  case '{':
	    ++tmpl, ++stack;
	    vs[stack].cur = cur;
	    vs[stack].type = tmpl;
	    vs[stack].vstate = tmpl + 1;
	    vs[stack].count = 0;
	    vs[stack].wstate = wht;
	    switch (*tmpl) {
	      default:
		wprintf(NULL, w_fatal, "unknown validate group %c\n", *tmpl);
		exit(1);

	      case 'A':		/* alternate group */
	      case 'O':		/* optional group */
	      case '*':		/* repeat zero or more times */
	      case '1':		/* repeat at least once */
		break;

	      case 'c':		/* conditional group */
		vs[stack].label = ++tmpl;
		while (*tmpl != '|' && *tmpl != '}' && *tmpl != '\0') ++tmpl;
		vs[stack].llen = tmpl - vs[stack].label;
		if (*tmpl == '|') ++tmpl;
		while (*tmpl != '\0' && *tmpl != '}' && *tmpl != ':') {
		    if (*tmpl == 'R') {
			memset(reqmap, 0, sizeof (reqmap));
			memset(reqlen, 0, sizeof (reqlen));
			callow = creq = cseen = 0;
			++tmpl;
			if (*tmpl == ':') ++tmpl;
			continue;
		    }
		    for (j = 0, scan = tmpl + 1; isdigit(*scan); ++scan) {
			j = j * 10 + (*scan - '0');
		    }
		    if (((*tmpl == 'K' || *tmpl == 'V') && j > 9) ||
			((*tmpl == 'M' || *tmpl == 'O') &&
			 (j < 1 || (size_t) j > sizeof (unsigned long) * 8))) {
			wprintf(db, w_fatal, "template conditional %c "
				"number %d out of range", *tmpl, j);
			exit(1);
		    }
		    switch (*tmpl) {
		      default:
			wprintf(db, w_fatal, "unknown template char %c",
				*tmpl);
			exit(1);
				
		      case 'V':	/* check value */
			if (hinfo->value != j) {
			    tmpl = skipvalseg(tmpl);
			    continue;
			}
			break;

		      case 'K':	/* check against kept token */
			tmpl = scan;
			if (*tmpl == '=') ++tmpl;
			for (tokend = tmpl;
			     *tokend != ':' && *tokend != '|' &&
			     *tokend != '}' && *tokend != '\0';
			     ++tokend)
			    ;
			if (tokcomp(tmpl, tokend - tmpl, ctx->mcur->keep[j])
			    != 0) {
			    tmpl = skipvalseg(tmpl);
			    continue;
			}
			break;

		      case 'M':	/* set mandatory flag */
			creq |= 1UL << (j - 1);
			/* fall through */
		      case 'O':	/* set optional flag */
			callow |= 1UL << (j - 1);
			break;
		    }
		    while (*tmpl != ':' && *tmpl != '|' &&
			   *tmpl != '}' && *tmpl != '\0') {
			++tmpl;
		    }
		    if (*tmpl == ':' || *tmpl == '|') ++tmpl;
		}
		if (*tmpl != ':') {
		    wprintf(db, w_fatal, "expected colon in template at %c",
			    *tmpl);
		    exit(1);
		}
		break;

	      case 'E':		/* enumeration */
	      case 'e':
		cond_enum = 0;
		if (*tmpl == 'e') {
		    cond_enum = 1;
		    switch (*++tmpl) {
		      case 'Q':
			cond_enum = 2;
			break;
		      case 'S':
			cond_enum = 3;
			break;
		    }
		}
		if (*++tmpl == ':') {
		    label = ++tmpl;
		    while (*tmpl != ':' && *tmpl != '|' && *tmpl != '}' &&
			   *tmpl != '\0') {
			++tmpl;
		    }
		    llen = tmpl - label;
		    if (*tmpl == ':' || *tmpl == '|') ++tmpl;
		} else {
		    label = enumtype;
		    llen = sizeof (enumtype) - 1;
		}
		if ((cond_enum < 2 && cur->type != tok_atom) ||
		    (cond_enum == 2 && cur->type != tok_qstring) ||
		    (cond_enum == 3 && cur->type != tok_atom &&
   		                       cur->type != tok_qstring)) {
		    --stack;
		    if (valreset(&stack, vs, &cur, &tmpl, &wht, &best)) {
			continue;
		    }
		    wprintf(db, w_error, "%T should be %.*s", cur,
			    llen, label);
		    tmpl = skipvalgroup(tmpl);
		    if (cur->type == tok_special && *cur->data != '.') {
			continue;
		    }
		    cur = cur->next;
		    continue;
		}
		success = 0;
		do {
		    /* handle conditionals */
		    j = 0;
		    if (cond_enum && (isdigit(*tmpl) || *tmpl == ':')) {
			while (isdigit(*tmpl)) {
			    j = j * 10 + (*tmpl - '0');
			    ++tmpl;
			}
			if (*tmpl != ':') continue;
			++tmpl;
		    }
		    /* find value */
		    for (tokend = tmpl;
			 *tokend != ':' && *tokend != '|' &&
			 *tokend != '}' && *tokend != '\0';
			 ++tokend)
			;
		    /* handle empty enumerated type as default case */
		    if (tokend == tmpl) {
			++tmpl;
			success = 1;
			if (label != enumtype) {
			    wprintf(db, w_unknown, "unknown %.*s '%t'",
				    llen, label, cur);
			}
			break;
		    }
		    /* cache value for enumerated conditional list */
		    if (j > 0 && j < 33) {
			reqmap[j - 1] = tmpl;
			reqlen[j - 1] = tokend - tmpl;
		    }
		    /* check for match, skip if we see end of group */
		    if (tokend - tmpl == cur->len &&
			tokcomp(tmpl, tokend - tmpl, cur) == 0) {
			if (cond_enum && j > 0 && j < 33) {
			    cseen |= (1UL << (j - 1));
			}
			tmpl = tokend;
			if (*tmpl == '|' || *tmpl == '}') {
			    tmpl = skipvalgroup(tmpl);
			    success = 1;
			    --stack;
			    break;
			}
			++tmpl;
			break;
		    }
		} while (*(tmpl = skipvalseg(tmpl)) != '}');
		if (!success && *tmpl == '}') {
		    --stack;
		    if (valreset(&stack, vs, &cur, &tmpl, &wht, &best)) {
			continue;
		    }
		    wprintf(db, w_unknown, "unknown %.*s '%t'",
			    llen, label, cur);
		    ++tmpl;
		}
		cur = cur->next;
		continue;

	      case 'S': /* skip to special */
	      case 's':
		j = *tmpl == 's';
		++tmpl;
		--stack;
		while (cur != NULL &&
		       (cur->type != tok_special || *cur->data != *tmpl)) {
		    cur = cur->next;
		}
		if (cur == NULL) {
		    if (valreset(&stack, vs, &cur, &tmpl, &wht, &best)) {
			continue;
		    }
		    cur = vs[stack + 1].cur;
		    wprintf(db, w_error, "expected %c at or after %T",
			       *tmpl, cur);
		    return;
		}
		if (j && cur != vs[stack + 1].cur) {
		    if (valreset(&stack, vs, &cur, &tmpl, &wht, &best)) {
			continue;
		    }
		    wprintf(db, w_error, "expected %c at %T",
			       *tmpl, vs[stack + 1].cur);
		}
		tmpl = skipvalgroup(tmpl);
		cur = cur->next;
		continue;

	      case 'Q': /* a quoted-string with sub-syntax */
	      case 'T': /* an atom with sub-syntax */
	      case 't':	/* an atom or quoted-string with sub-syntax */
		--stack;
		if ((cur->type != tok_atom && cur->type != tok_qstring) ||
		    (*tmpl == 'T' && cur->type != tok_atom) ||
		    (*tmpl == 'Q' && cur->type != tok_qstring)) {
		    if (valreset(&stack, vs, &cur, &tmpl, &wht, &best)) {
			continue;
		    }
		    wprintf(db, w_error, "%T should be a%s", cur,
			    *tmpl == 'T' ? "n atom" :
			    *tmpl == 'Q' ? " quoted-string" :
			    "n atom or quoted-string");
		    tmpl = skipvalgroup(tmpl);
		    cur = cur->next;
		    continue;
		}
		tokend = skipvalgroup(tmpl) - 1;
		++tmpl;
		validatechars(&tmpl, cur->data, cur->len, &j, &failstr);
		if (j == -1) {
		    wprintf(db, w_fatal, "Unknown template char at '%s'",
			    tmpl);
		    exit(1);
		} else if (failstr) {
		    if (valreset(&stack, vs, &cur, &tmpl, &wht, &best)) {
			continue;
		    }
		    if (failstr[0] == ':') {
			wprintf(db, w_error, "%s%c at position %d in %T",
				   failstr + 1, *tmpl, j + 1, cur);
		    } else {
			wprintf(db, w_error, "%T position %d should be %s",
				cur, j + 1, failstr);
		    }
		} else if (j < cur->len) {
		    if (valreset(&stack, vs, &cur, &tmpl, &wht, &best)) {
			continue;
		    }
		    wprintf(db, w_error, "unexpected extra chars '%.*s' in %T",
			    cur->len - j, cur->data + j, cur);
		} else if (*tmpl != '}') {
		    if (valreset(&stack, vs, &cur, &tmpl, &wht, &best)) {
			continue;
		    }
		    wprintf(db, w_error, "additional char syntax '%.*s' "
			    "expected after %T", tokend - tmpl, tmpl, cur);
		}
		cur = cur->next;
		tmpl = tokend + 1;
		continue;
	    }
	    break;
	    

	  case '.':
	  case '@':
	  case ':':
	  case ';':
	  case '<':
	  case '>':
	  case '=':
	  case ',':
	  case '\\':
	  case '/':
	  case '?':
	    if (cur->type != tok_special || *tmpl != *cur->data) {
		if (valreset(&stack, vs, &cur, &tmpl, &wht, &best)) continue;
		wprintf(db, w_error, "expected %c and saw %T", *tmpl, cur);
		/* people often omit '<' by accident, don't skip token
		 */
		if (*tmpl != '<') cur = cur->next;
	    } else {
		cur = cur->next;
	    }
	    break;

	  default:
	    if (cur->type != tok_atom || cur->len != 1
		|| *tmpl != *cur->data) {
		if (valreset(&stack, vs, &cur, &tmpl, &wht, &best)) continue;
		wprintf(db, w_error, "expected %c and saw %T", *tmpl, cur);
	    }
	    cur = cur->next;
	    break;
	    
	  case '$':
	    return;
	}
	++tmpl;
    }
    while (cur != NULL && cur->type == tok_comment) cur = cur->next;
    if (cur != NULL) {
	if (best.tok != NULL)  {
	    if (best.tok->toknum > cur->toknum) {
		cur = best.tok;
	    }
	    wprintf(db, w_error, "unexpected tokens at end of ");
	    tokprint(w_error, cur);
	} else {
	    wprintf(db, w_error, "missing tokens '%s' at end of ", best.tmpl);
	}
    } else if (verbose) {
	wprintf(db, w_ok, "validated ");
    }
}

/* validate charset param
 */
static void validate_charset(MIMEinfo *mcur, msgtoken *cset, int lineno)
{
    static const char iso8859[] = "iso-8859-";

    mcur->asciisubset = 0;
    mcur->cset7bit = 0;
    if (tokcomp("us-ascii", -1, cset) == 0) {
	mcur->csetid = us_ascii;
	mcur->cset7bit = 1;
	return;
    }
    if (tokcomp("utf-7", -1, cset) == 0 ||
        tokcomp("unicode-1-1-utf-7", -1, cset) == 0) {
	mcur->csetid = utf7;
	mcur->cset7bit = 1;
        wprintf(NULL, w_warn, "Use 'utf-8' charset instead of utf-7 for "
               "better backwards compatibility, line %d", lineno);
        return;
    }
    if (tokcomp("x-unicode-2-0-utf-7", -1, cset) == 0) {
        wprintf(NULL, w_warn, "Use 'utf-8' charset instead of utf-7 for "
               "better backwards compatibility, line %d", lineno);
    }
    if (tokcomp("koi8-r", -1, cset) == 0) {
	mcur->asciisubset = 1;
	mcur->csetid = koi8_r;
	return;
    }
    if (tokcomp("utf-8", -1, cset) == 0) {
	mcur->asciisubset = 1;
	mcur->csetid = utf8;
	return;
    }
    if (tokcomp("iso2022-jp", -1, cset) == 0) {
	mcur->asciisubset = 2;
	mcur->csetid = iso2022_jp;
	mcur->cset7bit = 1;
	return;
    }
    if (tokcomp("iso2022-cn", -1, cset) == 0) {
	mcur->asciisubset = 2;
	mcur->csetid = iso2022_cn;
	mcur->cset7bit = 1;
	return;
    }
    if (tokcomp("shift_jis", -1, cset) == 0) {
	mcur->asciisubset = 1;
	mcur->csetid = shift_jis;
	return;
    }
    if (tokprefix(iso8859, sizeof (iso8859) - 1, cset) == 0) {
	mcur->asciisubset = 1;
	mcur->csetid = iso8859_any;
        return;
    }
    if (tokprefix("x-", 2, cset) == 0) {
	wprintf(NULL, w_warn, "unknown experimental charset '%t' on "
	    "line %d", cset, lineno);
    } else {
	wprintf(NULL, w_unknown, "unknown charset '%t' on "
	    "line %d", cset, lineno);
    }
    mcur->csetid = cset_unknown;
}

/* parse an 822, MIME or DSN header
 */
static void parsehead(msgcontext *ctx, struct headmap *hmap,
		      const char *body, int len, int htype,
		      headinfo *hinfo, dbinfo *db)
{
    msgtoken *parse, *cur, *lasttok, *subtok;
    MIMEinfo *mcur = ctx->mcur;
    int j, do_parse = verbose;

    if (hmap->type == head_unknown) {
	wprintf(NULL, w_fatal, "unknown header line %d", db->startline);
	exit(1);
    }

    parse = tokenize(ctx, body, len, hmap->flags, db);
    
    /* strip leading comments */
    if (parse != NULL && parse->type == tok_comment &&
	(hmap == NULL || *hmap->parse != 'C')) {
	wprintf(db, w_warn, "starting with comment unwise");
	while (parse != NULL && parse->type == tok_comment) {
	    cur = parse->next;
	    parse->next = msgfree;
	    msgfree = parse;
	    parse = cur;
	}
    }
    
    /* check for empty header */
    if (parse == NULL) {
	wprintf(db, w_error, "empty ");
	return;
    }

    /* check for inappropriate header */
    if ((htype == HEAD_MIME && (hmap->flags & HF_OK_MASK) != 0) ||
	((htype == HEAD_MSG || htype == HEAD_INNER || htype == HEAD_TEXT ||
	  htype == HEAD_EXTB) &&
	 (hmap->flags & HF_OK_MASK) != 0 && (hmap->flags & MSG_OK) == 0) ||
	(htype == HEAD_DSN && !(hmap->flags & DSN_OK)) ||
	(htype == HEAD_RCPT && !(hmap->flags & DSNRCPT_OK)) ||
	(htype == HEAD_MTRKM && !(hmap->flags & MTRKM_OK)) ||
	(htype == HEAD_MTRKR && !(hmap->flags & MTRKR_OK)) ||
	(htype == HEAD_MDN && !(hmap->flags & MDN_OK))) {
	j = db->headlen;
	db->headlen = 0;
	wprintf(db, w_warn, "'%.*s' unexpected in %s", j, db->headname,
		headtypename[htype]);
	db->headlen = j;
    } else if (htype == HEAD_MIME &&
	       (db->headlen < 9 || strncasecmp("content-", db->headname, 8))) {
	wprintf(db, w_warn, "MIME headers should only be 'Content-*'. "
		"No meaning will apply to ");
    }
    
    /* parse headers */
    if (hmap->parse != NULL) {
	validatehead(ctx, hmap->parse, parse, hinfo, hmap, db);
    }

    /* special case headers */
    switch (hmap->type) {
      case contenttype:
	mcur->typenum = (ctypeid) hinfo->value;
	if  (mcur->typenum == ct_unknown &&
	     tokprefix("x-", 2, mcur->keep[K_CTYPE]) == 0) {
	    wprintf(db, w_warn, "experimental top-level type '%t' "
		    "strongly discouraged (" RFC_MIME_XTY ") line %d",
		    mcur->keep[K_CTYPE], ctx->lineno);
	} else if (tokprefix("x-", 2, mcur->keep[K_SUBTYPE]) == 0) {
	    wprintf(db, w_warn, "use of experimental media subtype '%t' "
		    "in released software unwise line %d",
		    mcur->keep[K_SUBTYPE], ctx->lineno);
	}
	if (mcur->typenum == text) {
	    if (mcur->keep[K_CHARSET] != NULL) {
	        validate_charset(mcur, mcur->keep[K_CHARSET], ctx->lineno);
	    }
	} else if (mcur->typenum == multipart) {
	    if (mcur->keep[K_BOUNDARY] == NULL) {
		mcur->typenum = ct_unknown;
		wprintf(db, w_error, "multipart missing boundary parameter");
	    } else {
		if (tokcomp("report", -1, mcur->keep[K_SUBTYPE]) == 0) {
		    mcur->inreport = 1;
		} else if (tokcomp("related", -1,
				   mcur->keep[K_SUBTYPE]) == 0) {
		    mcur->inrelated = 1;
		    if (mcur->keep[K_RELTYPE] != NULL) {
			subtok = tokenize(ctx, mcur->keep[K_RELTYPE]->data,
					  mcur->keep[K_RELTYPE]->len,
					  STRUCTURED|TSPECIAL, db);
			db->flags |= DB_INTYPE;
			validatehead(ctx, type_syntax, subtok, hinfo,
				     hmap, db);
			db->flags &= ~DB_INTYPE;
			if (subtok != NULL) {
			    for (lasttok = subtok; lasttok->next != NULL;
				 lasttok = lasttok->next)
				;
			    lasttok->next = msgfree;
			    msgfree = subtok;
			}
		    }
		} else if (tokcomp("digest", -1,
				   mcur->keep[K_SUBTYPE]) == 0) {
		    mcur->indigest = 1;
		}
	    }
	}
	break;
	
      default:
	if (hmap->parse == NULL &&
	    (hmap->flags & HEADTYPE_MASK) != UNSTRUCTURED) {
	    do_parse = 1;
	}
	break;
    }

    if (do_parse) {
	wprintf(db, w_ok, "Parse of ");
	tokprint(w_ok, parse);
    }
    
    /* put parse result on free list */
    while (parse != NULL) {
	for (j = 0; j < 10 && parse != mcur->keep[j]; ++j)
	    ;
	cur = parse->next;
	if (j == 10) {
	    parse->next = msgfree;
	    msgfree = parse;
	}
	parse = cur;
    }

    return;
}

/* parse 822, MIME or DSN headers
 */
static int parseheaders(msgcontext *ctx, const char **pmsg,
			int *plen, int htype)
{
    const char *line, *vline, *fieldbody, *msg = *pmsg;
    struct headmap *hmap;
    dbinfo db;
    int firstline = 1, mandhead, startline, hflags = 0, hinum, j, pos;
    headinfo hinfo[mischead + 1];
    unsigned char duptab[DUPTABSIZE];

    /* init header info and duplicate table */
    memset(duptab, 0, sizeof (duptab));
    memset(hinfo, 0, sizeof (hinfo));

    /* allocate MIME info, if necessary */
    if (ctx->mcur == ctx->mpart) {
	ctx->mcur = malloc(sizeof (MIMEinfo));
	if (ctx->mcur == NULL) {
	    wprintf(NULL, w_fatal, "out of memory");
	    return (-1);
	}
	memset(ctx->mcur, 0, sizeof (MIMEinfo));
    } else {
	for (j = 0; j < 10; ++j) {
	    if (ctx->mcur->keep[j] != NULL) {
		ctx->mcur->keep[j]->next = msgfree;
		msgfree = ctx->mcur->keep[j];
		ctx->mcur->keep[j] = NULL;
	    }
	}
    }
    ctx->mcur->typenum = text;
    if (ctx->mpart && ctx->mpart->indigest == 1) {
	ctx->mcur->typenum = message;
    }
    ctx->mcur->cte = cte_default;
    ctx->mcur->saw8bit = 0;
    ctx->mcur->saw8char = 0;
    ctx->mcur->textplain = 0;
    ctx->mcur->csetid = us_ascii;
    ctx->mcur->asciisubset = 0;
    ctx->mcur->cset7bit = 0;
    startline = ctx->lineno;
    db.endline = ctx->lineno;
    for (;;) {

	/* look for a header name */
	line = vline = msg;
	while (isalpha(*msg) || isdigit(*msg) || *msg == '-') {
	    ++msg;
	}
	/* handle end of line */
	if ((*msg == '\n' || *msg == '\r') && msg == line) {
	    ++line, ++ctx->lineno;
	    break;
	}
	/* handle "header   : body" */
	for (j = 0; *msg == ' ' || *msg == '\t'; ++msg, ++j)
	    ;
	if (*msg == '\n' || *msg == '\r') {
	    msg -= j;
	    j = 0;
	}
	hmap = &emptyhead;
	if (*msg == '\0') {
	    wprintf(NULL, w_error, "message ended in middle of header at "
		    "line %d", ctx->lineno);
	    break;
	}
	if (*msg != ':' || msg == line) {
	    wprintf(NULL, w_error, "unexpected character %c"
		    " found in header on line %d", *msg, ctx->lineno);
	} else /* msg == ':' */ {
	    if (j) {
		wprintf(NULL, w_warn, "spaces between header name and "
			"':' unwise on line %d", ctx->lineno);
	    }
	    
	    /* lookup the header name */
	    for (hmap = known_headers; hmap->str != NULL &&
		     (strlen(hmap->str) != (size_t) (msg - line - j) ||
		  strncasecmp(hmap->str, line, msg - line - j)); ++hmap)
		;
	    fieldbody = ++msg;
	    hflags |= hmap->flags;
	}
	firstline = 0;

	/* find the end of the header */
	db.startline = ctx->lineno;
	db.headname = line;
	db.headlen = msg - line - j - 1;
	db.flags = 0;
	pos = msg - line;
	while (*msg != '\0') {
	    if (*msg == '\n' || *msg == '\r') {
		if (htype == HEAD_DSN || htype == HEAD_RCPT ||
		    htype == HEAD_MTRKM || htype == HEAD_MTRKR ||
		    htype == HEAD_MDN || htype == HEAD_TEXT) {
		    MD5Update(&ctx->md5, (unsigned char *) vline, msg - vline);
		    MD5Update(&ctx->md5, (unsigned char *) "\r\n", 2);
		}
		if (pos > 80) {
		    wprintf(NULL, w_warn, "line too long in header '%.*s' "
			    "at line %d", fieldbody - line, line, ctx->lineno);
		}
		pos = 0;
		++ctx->lineno;
		if (*msg == '\r' && msg[1] == '\n') ++msg;
		vline = ++msg;
		if (*msg != ' ' && *msg != '\t') {
		    break;
		}
		while (*msg == ' ' || *msg == '\t') ++msg, ++pos;
		if (*msg == '\n' || *msg == '\r') {
		    wprintf(NULL, w_warn, "empty continuation line in "
			    "header '%.*s' at line %d",
			    fieldbody - line, line, ctx->lineno);
		    continue;
		}
	    }
	    ++msg, ++pos;
	}
	db.endline = ctx->lineno - 1;

	/* parse the header */
	if (hmap->type != head_unknown) {
	    if (hmap->type == returnpath && reply_line == NULL) {
		reply_line = fieldbody + 1;
		reply_len = msg - fieldbody - 1;
	    }

	    /* check for duplicate headers */
            hinum = hmap - known_headers;
	    if (duptab[hinum] && (hmap->flags & DUPOK) == 0) {
	    	wprintf(&db, htype == HEAD_DSN || htype == HEAD_RCPT ||
			htype == HEAD_MTRKM || htype == HEAD_MTRKR ||
			htype == HEAD_MDN ? w_error : w_warn,
			"duplicate ");
	    }
	    duptab[hinum] = 1;
	    hinfo[hmap->type].flags = HEAD_PRESENT;
	    hinfo[hmap->type].value = 0;
	    parsehead(ctx, hmap, fieldbody, msg - fieldbody - 1, htype,
	    	hinfo + hmap->type, &db);
	} else if (hmap != &emptyhead) {
	    wprintf(&db, htype == HEAD_DSN || htype == HEAD_RCPT ||
		    htype == HEAD_MTRKM || htype == HEAD_MTRKR ||
		    htype == HEAD_MDN ? w_error : w_unknown,
		    "unknown ");
	}

	/* advance */
	line = msg;
    }
    *plen -= line - *pmsg;
    *pmsg = line;

    /* handle silence */
    if (silent) return (0);
    
    /* check for mandatory headers in header blocks */
    mandhead = 0;
    switch (htype) {
    	case HEAD_MSG:
	    if (hflags & HF_PATH) {
		mandhead = HF_NEWSGROUPS | HF_MID | HF_SUBJECT | HF_DATE |
		    HF_FROM;
		break;
	    }
	    mandhead = HF_DATE | HF_FROM | HF_RETURNPATH;
	    if ((hflags & (HF_TO|HF_CC|HF_BCC)) == 0) {
		wprintf(NULL, w_error, "At least one of To, CC, or BCC "
			"required lines %d-%d (" RFC_TOCCBCC ")",
			startline, db.endline);
	    }
    	    break;
    	    
        case HEAD_DSN:
            mandhead = HF_REPORTMTA;
            break;
            
        case HEAD_RCPT:
            mandhead = HF_ACTION | HF_STATUS | HF_FINALRCPT;
            break;

	case HEAD_MTRKM:
	    mandhead = HF_REPORTMTA | HF_ORIGENVID | HF_ARRIVDATE;
	    break;

	case HEAD_MTRKR:
	    mandhead = HF_ACTION | HF_STATUS | HF_FINALRCPT | HF_ORIGRCPT;
	    break;
        
        case HEAD_INNER:
            if ((hflags & (HF_DATE|HF_FROM|HF_SUBJECT)) == 0) {
                wprintf(NULL, w_error, "At least one of Date, From, Subject "
			"required lines %d-%d (" RFC_MIME_DFS ")",
			startline, db.endline);
            }
            break;

	  case HEAD_EXTB:
	    if ((hflags & HF_CID) == 0) {
		wprintf(NULL, w_error, "Content-ID required lines %d-%d ("
			RFC_EXTB_CID ")", startline, db.endline);
	    }
	    break;
    }
    if (mandhead) for (hmap = known_headers; hmap->str != NULL; ++hmap) {
        if ((hmap->flags & mandhead) != 0 &&
            (hmap->flags & mandhead & hflags) == 0) {
            wprintf(NULL, w_error, "missing mandatory header '%s' lines %d-%d",
            	   hmap->str, startline, db.endline);
        }
    }

    /* check for name content-type param and missing disposition filename */
    if ((hinfo[contenttype].flags & 1) &&
	(hinfo[contentdisp].flags & 1) == 0) {
	wprintf(NULL, w_error, "Content-Type 'name' parameter deprecated in "
		"favor of Content-Disposition 'filename' parameter ("
		RFC_CDISP_FN ") lines %d-%d", startline, db.endline);
    }
    
    /* make sure return-path is empty on a multipart/report */
    if (ctx->mcur->inreport && (hinfo[returnpath].flags & 1)) {
        wprintf(NULL, w_error, "return-path should be empty on "
		"multipart/report lines %d-%d", startline, db.endline);
    }
    
    /* if from multi-valued, sender is mandatory */
    if ((hinfo[fromhead].flags & 1) && !(hflags & HF_SENDER)) {
        wprintf(NULL, w_error, "'Sender' header is mandatory when 'From' is "
		"multi-valued lines %d-%d", startline, db.endline);
    }

    /* if Lines is present, Newsgroups must also be there */
    if (hflags & HF_LINES) {
	if (!(hflags & HF_NEWSGROUPS)) {
	    wprintf(NULL, w_warn, "'Lines' header is not standardized for use "
		    "in email lines %d-%d", startline, db.endline);
	}
	if (htype == HEAD_MSG) {
	    ctx->lines = hinfo[lineshead].value;
	    ctx->endhead = ctx->lineno;
	}
    }
    
    /* save content-transfer-encoding */
    if (hinfo[contentte].value) {
        ctx->mcur->cte = (cteid) hinfo[contentte].value;
        if (ctx->mcur->cte >= quoted_printable &&
            (ctx->mcur->typenum == multipart ||
             (ctx->mcur->typenum == message &&
              tokcomp("rfc822", -1, ctx->mcur->keep[K_SUBTYPE]) == 0))) {
            wprintf(NULL, w_error, "only 7-bit, 8-bit and binary "
		    "content-transfer-encodings are permitted on "
		    "compound media types, line %d", ctx->lineno);
        }
        if (ctx->mcur->cte == cte8bit && ctx->mpart != NULL &&
            ctx->mpart->cte != cte8bit) {
            wprintf(NULL, w_error, "mismatch between inner "
		    "content-transfer-encoding and that of enclosing "
		    "multipart, line %d", ctx->lineno);
        }
    }
    
    /* warn about charset/cte mismatch */
    if (ctx->mcur->typenum == text && ctx->mcur->cte == cte8bit) {
        if (ctx->mcur->csetid == us_ascii) {
	    wprintf(NULL, w_error, "charset 'us-ascii' doesn't match "
		    "content-transfer-encoding line %d", ctx->lineno);
	} else if (ctx->mcur->cset7bit) {
	    wprintf(NULL, w_error, "charset '%t' doesn't match "
		    "content-transfer-encoding line %d",
		    ctx->mcur->keep[K_CHARSET], ctx->lineno);
	}
    }

    /* put multipart on boundary list */
    if (ctx->mcur->typenum == multipart) {
	ctx->mcur->next = ctx->mpart;
	ctx->mpart = ctx->mcur;
    }

    return (0);
}

/* process a MIME body, looking for a MIME boundary
 *  returns 1 if part found, 0 if end of message, -1 on fatal error
 */
static int findboundary(msgcontext *ctx, const char **pmsg, int *plen,
			int preamble)
{
    const char *dat, *dend, *line, *msg, *dlinetext;
    char *dst;
    int blen, epilogue, softlen, dlineno;
    int curlinebreak, lastlinebreak, sawcr, hlow, hhigh, utf8code;
    int saw8bit, sawsoft, softspace, qplen, endline, sawesc;
    utf8state ut8;
    int badqp, r;
    cteid cte;
    MIMEinfo *minfo;
    msgtoken *cur;
    base64ctx bctx;
    char databuf[1024];
    unsigned char mdresult[16], mdmatch[16];

    /* initialize */
    msg = *pmsg;
    memset(&bctx, 0, sizeof (bctx));
    badqp = 1;
    softlen = 0;
    sawcr = 0;
    sawsoft = 0;
    softspace = 0;
    qplen = 0;
    lastlinebreak = 0;
    endline = 0;
    epilogue = 0;
    sawesc = 0;
    ut8.state = 0;
    dlineno = 1;
    cte = ctx->mcur->cte;

    /* loop until end of body part / message */
    while (*msg != '\0') {
	/* scan to end of line */
	line = msg;
	saw8bit = 0;
	while (*msg != '\0' && *msg != '\n' && *msg != '\r') {
	    if ((unsigned char) *msg >= 128) {
		saw8bit = 1;
	    }
	    ++msg;
	}
	qplen += msg - line;

	/* check for MIME boundary */
	if (msg - line > 2 && line[0] == '-' && line[1] == '-' &&
	    ctx->mpart != NULL) {
	    /* find end of boundary marker */
	    for (dat = msg; isspace(dat[-1]); --dat)
		;

	    /* check if it could be an end boundary */
	    blen = 2;
	    if (!preamble && dat - line > 4 &&
		dat[-1] == '-' && dat[-2] == '-') {
		blen = 4;
	    }

	    /* cache saw8bit flag */
	    ctx->mpart->saw8bit |= ctx->mcur->saw8bit;

	    /* look for known matching boundary line */
	    for (minfo = ctx->mpart; minfo != NULL; minfo = minfo->next) {
		cur = minfo->keep[K_BOUNDARY];
		if ((cur->len == dat - line - blen ||
		     cur->len == dat - line - 2) &&
		    strncmp(line + 2, cur->data, cur->len) == 0) {
		    break;
		}
	    }

	    /* found a matching boundary line */
	    if (minfo != NULL) {
		/* check for unbalanced boundary */
		if (cur != ctx->mpart->keep[K_BOUNDARY]) {
		    wprintf(NULL, w_error, "unbalanced MIME boundary "
			    "line %d", ctx->lineno);
		    do {
			minfo = ctx->mpart->next;
			minfo->saw8bit |= ctx->mpart->saw8bit;
			disposeminfo(ctx->mpart);
			ctx->mpart = minfo;
		    } while (cur != minfo->keep[K_BOUNDARY]);
		}

		/* end loop unless we're at an end boundary */
		if (blen == 2 || cur->len != dat - line - blen) break;

		/* handle end boundary; switch to epilogue mode */
		epilogue = 1;
		endline = ctx->lineno;
		cte = cte7bit;
		if (verbose) {
		    wprintf(NULL, w_ok, "found end boundary line %d",
			    ctx->lineno);
		}
		ctx->mpart = minfo->next;
		if (ctx->mpart != NULL) {
		    ctx->mpart->saw8bit |= minfo->saw8bit;
		}
		
		/* do 8-bit check */
		if (minfo->saw8bit && minfo->cte != cte8bit) {
		    wprintf(NULL, w_error, "Content-Transfer-Encoding "
			    "doesn't permit 8-bit characters in body "
			    "ending line %d", ctx->lineno);
		} else if (!minfo->saw8bit && minfo->cte == cte8bit) {
		    wprintf(NULL, w_warn, "Content-Transfer-Encoding "
			    "mislabelled as 8-bit when 7-bit suffices "
			    "multipart ending line %d", ctx->lineno);
		}
		
		disposeminfo(minfo);
		goto NEXTLINE;
	    }
	}

	/* check for invalid 8-bit */
	if (saw8bit && cte != cte8bit) {
	    if (preamble || epilogue) {
		wprintf(NULL, w_error, "8-bit characters not permitted in "
			"preamble/epilogue line %d", ctx->lineno);
	    } else {
		wprintf(NULL, w_error, "Content-Transfer-Encoding doesn't "
			"permit 8-bit characters line %d", ctx->lineno);
	    }
	}
	if (!preamble && !epilogue) {
	    ctx->mcur->saw8bit |= saw8bit;
	}
	
	/* decode CTE */
	curlinebreak = 1;
	if (cte == quoted_printable) {
	    if (msg - line > 76) {
		wprintf(NULL, w_error, "quoted-printable line %d too long "
			RFC_QP_LEN, ctx->lineno);
	    }
	    dat = line;
	    dst = databuf;
	    while (dat < msg && (size_t) (dst - databuf) < sizeof (databuf)) {
		/* quoted-printable escape char */
		if (*dat != '=') {
		    if ((*dat != '\t' && *dat < ' ') ||
			(unsigned char) *dat > 127) {
			wprintf(NULL, w_error, "character %c should be "
				"quoted-printable encoded line %d", *dat,
				ctx->lineno);
		    }
		    if (!isspace(*dat)) softspace = 0;
		    *dst = *dat;
		    ++dst, ++dat;
		    continue;
		}

		/* soft linebreak */
		if (dat[1] == '\n' || dat[1] == '\r') {
		    curlinebreak = 0;
		    softspace = dat > line && isspace(dat[-1]);
		    sawsoft = ctx->lineno;
		    break;
		}
		softspace = 0;

		/* hex encoding */
		if ((hhigh = hex_table[(unsigned char) dat[1]]) == 16 ||
		    (hlow = hex_table[(unsigned char) dat[2]]) == 16) {
		    wprintf(NULL, w_error, "invalid quoted-printable "
			    "sequence '%.*s' line %d (" RFC_QP_BAD ")",
			    3, dat, ctx->lineno);
		    *dst = *dat;
		    ++dst, ++dat;
		    continue;
		}
		hlow += hhigh * 16;
		if (hlow != '\t' && hlow > ' ' &&
		    hlow != '=' && hlow < 127 &&
		    (hlow != '.' || dat != line || !lastlinebreak)) {
		    wprintf(NULL, w_warn, "Unnecessary "
			    "quoted-printable encoding of %c line %d",
			    hlow, ctx->lineno);
		    qplen -= 2;
		} else if (hlow != '=') {
		    badqp = 0;
		}
		dat += 3;
		*dst = hlow;
		++dst;
	    }
	    dat = databuf;
	    dend = dst;
	} else if (cte == base64) {
	    if (msg - line > 76) {
		wprintf(NULL, w_warn, "base64 line %d too long ("
			RFC_B64_LEN ")", ctx->lineno);
	    }
	    dst = databuf;
	    dat = line;
	    r = 0;
	    while (dat < msg) {
		r = decode64(&bctx, dat, msg - dat, dst,
			     sizeof (databuf) - (dst - databuf));
		dst += bctx.outlen;
		if (r != -1) break;
		wprintf(NULL, w_warn, "non-base64 character %c line %d",
			bctx.badc, ctx->lineno);
		/* skip over valid chars & block of invalid chars */
		while (dat < msg && CHAR64(*dat) != XX) ++dat;
		while (dat < msg && CHAR64(*dat) == XX) ++dat;
	    }
	    dat = databuf;
	    dend = dst;
	    if (r == -4) {
		wprintf(NULL, w_warn, "excess characters at end of base64 "
			"line %d", ctx->lineno);
	    } else if (r == 1) {
		wprintf(NULL, w_warn, "base64 should end on a "
			"4-character boundary line %d\n", ctx->lineno);
	    }
	    curlinebreak = 0;
	} else {
	    dat = line;
	    dend = msg;
	}

	/* update MD5 context */
	if (!preamble && !epilogue) {
	    if (curlinebreak) {
		if (sawsoft) {
		    if (qplen < 76 && !softspace) {
			wprintf(NULL, w_warn, "Unnecessary quoted-printable "
				"soft line break line %d", sawsoft);
		    } else {
			badqp = 0;
		    }
		}
		sawsoft = 0;
		qplen = 0;
		softspace = 0;
	    }
	    if (lastlinebreak) {
		MD5Update(&ctx->md5, (unsigned char *) "\r\n", 2);
	    }
	    MD5Update(&ctx->md5, (unsigned char *) dat, dend - dat);
	}
	if (lastlinebreak) {
	    ++dlineno;
	    softlen = 0;
	}
	lastlinebreak = curlinebreak;

	/* scan decoded text for length & dubious characters */
	if (ctx->mcur->typenum == text) {
	    dlinetext = cte == base64 ? "decoded line" : "line";
	    while (dat < dend) {
		if (ctx->mcur->csetid == utf8) {
		    utf8code = utf8_table[(unsigned char) *dat];
		    if (ut8.state) {
			if (utf8code == EXT) {
			    --softlen;
			} else {
			    wprintf(NULL, w_error, "invalid UTF-8 octet %c "
				    "%s %d", *dat, dlinetext,
				    cte == base64 ? dlineno : ctx->lineno);
			}
			ut8.value = (ut8.value << 6) + (*dat & 0x3f);
			if (--ut8.state == 0) {
			    if ((ut8.charsize == 1 && ut8.value < 0x80) ||
				(ut8.charsize == 2 && ut8.value < 0x800) ||
				(ut8.charsize == 3 && ut8.value < 0x10000)) {
				wprintf(NULL, w_error, "invalid zero-padding "
					"on UTF-8 character U+%x %s %d",
					ut8.value, dlinetext,
					cte == base64 ? dlineno : ctx->lineno);
			    } else if (ut8.value >= 0xD800 &&
				       ut8.value <= 0xDFFF) {
				wprintf(NULL, w_error, "invalid UTF-8 "
					"encoding of surrogate U+%x %s %d",
					ut8.value, dlinetext,
					cte == base64 ? dlineno : ctx->lineno);
			    }
			}
		    } else if (utf8code == EXT || utf8code == BAD) {
			wprintf(NULL, w_error, "invalid UTF-8 octet %c "
				"%s %d", *dat, dlinetext,
				cte == base64 ? dlineno : ctx->lineno);
		    } else {
			ut8.state = ut8.charsize = utf8code - 1;
			switch (utf8code) {
			case 2:
			    ut8.value = utf8code & 0x1f;
			    break;
			case 3:
			    ut8.value = utf8code & 0x0f;
			    break;
			case 4:
			    ut8.value = utf8code & 0x07;
			    break;
			}
		    }
		}
		if (*dat == '\022') {
		    sawesc = 1;
		}
		if (*dat == '\n') {
		    if (!sawcr) {
			wprintf(NULL, w_error, "bare newline in text body "
				"decoded line %d", dlineno);
		    } else if (cte == quoted_printable) {
			wprintf(0, w_error, "Encoded CRLF in quoted-printable "
				"forbidden line %d\n", ctx->lineno);
		    } else {
			++dlineno;
			if (softlen > 79 && ctx->mcur->textplain == 1) {
			    wprintf(0, w_warn, "decoded line %d too long "
				    "(%d chars); text/plain shouldn't need "
				    "folding (" RFC_MIME_LB ")", dlineno,
				    softlen);
			}
			softlen = 0;
		    }
		    sawcr = 0;
		    ++dat;
		    continue;
		}
		if (sawcr) {
		    sawcr = 0;
		    wprintf(NULL, w_error, "bare carriage return in text body "
			    "decoded line %d", dlineno);
		}
		if (*dat == '\r') {
		    sawcr = 1;
		    ++dat;
		    continue;
		}
		if ((unsigned char) *dat > 127) {
		    ctx->mcur->saw8char = 1;
		    if ((unsigned char) *dat < 160 &&
			ctx->mcur->csetid == iso8859_any) {
			wprintf(NULL, w_error, "invalid ISO-8859-* "
				"character %c (" RFC_BAD8859 ") %s %d",
				*dat, dlinetext,
				cte == base64 ? dlineno : ctx->lineno);
		    } else if (cte != cte7bit && ctx->mcur->csetid <= utf7) {
			wprintf(NULL, w_error, "character set doesn't permit "
				"8-bit characters (%c) %s %d", *dat, dlinetext,
				cte == base64 ? dlineno : ctx->lineno);
		    }
		}
		++softlen;
		++dat;
	    }
	}
	
	/* line length check */
	if (curlinebreak && softlen > 79 && ctx->mcur->textplain == 1) {
	    wprintf(0, w_warn, "%sline %d too long (%d chars); text/plain "
		    "shouldn't need folding (" RFC_MIME_LB ")",
		    cte == quoted_printable ? "decoded " : "",
		    ctx->lineno, softlen);
	}
	
	/* exit if end of message */
	if (*msg == '\0') break;
	
	/* print line if in preamble/epilogue */
	if (!quiet) {
	    if (preamble) {
		wprintf(NULL, w_ok, "preamble %d: %.*s",
			ctx->lineno, msg - line, line);
	    } else if (epilogue) {
		wprintf(NULL, w_ok, "epilogue %d: %.*s\n",
			ctx->lineno, msg - line, line);
	    }
	}
	
      NEXTLINE:
	if (*msg == '\n' || *msg == '\r') {
	    if (*msg == '\r' && msg[1] == '\n') ++msg;
	    ++msg, ++ctx->lineno;
	}
    }

    if (!endline) endline = ctx->lineno;

    /* check for base64 errors */
    if (ctx->mcur->cte == base64) {
	if (bctx.tmplen) {
	    wprintf(NULL, w_error, "incomplete base64 in body part "
		    "ending line %d", endline);
	} else if (softlen > 78 && ctx->mcur->textplain == 1) {
	    wprintf(NULL, w_warn, "last decoded line too long; text/plain "
		   "shouldn't need folding (" RFC_MIME_LB ")");
	}
    }
		
    /* MD5 validation */
    MD5Final(mdresult, &ctx->md5);
    if (ctx->mcur->keep[K_MD5] != NULL) {
	memset(&bctx, 0, sizeof (bctx));
	r = decode64(&bctx, ctx->mcur->keep[K_MD5]->data,
		     ctx->mcur->keep[K_MD5]->len,
		     (char *) mdmatch, sizeof (mdmatch));
	if (r != 0 || bctx.outlen != sizeof (mdmatch)) {
	    wprintf(NULL, w_error, "invalid base64 in Content-MD5 header "
		    "line %d", ctx->mcur->keep[K_MD5]->lineno);
	} else if (memcmp(mdmatch, mdresult, sizeof (mdmatch)) == 0) {
	    wprintf(NULL, w_ok, "Content-MD5 %m validated", mdresult);
	} else {
	    wprintf(NULL, w_error, "Content-MD5 validation failed: "
		    "header=%m actual=%m", mdmatch, mdresult);
	}
    } else if ((verbose || show_md5) && !preamble) {
	wprintf(NULL, w_ok, "MD5=%m", mdresult);
    }
    
    /* do 8-bit check */
    if (!preamble && !ctx->mcur->saw8bit) {
	if (ctx->mcur->cte == cte8bit) {
	    wprintf(NULL, w_warn, "Content-Transfer-Encoding mislabelled "
		    "as 8-bit when 7-bit suffices, line %d", endline);
	} else if ((ctx->mcur->asciisubset == 1 && !ctx->mcur->saw8char)
		    || (ctx->mcur->asciisubset == 2 && !sawesc)) {
	    wprintf(NULL, w_warn, "Character set mislabelled as '%t' "
		    "when 'us-ascii' suffices, body part ending line %d",
		    ctx->mcur->keep[K_CHARSET], endline);
	}
    }

    /* check for unnecessary quoted-printable */
    if (ctx->mcur->cte == quoted_printable && badqp) {
	wprintf(NULL, w_warn, "quoted-printable used without need on "
		"body part ending line %d", endline);
    }

    /* check for end of message without seeing a boundary */
    if (*msg == '\0') {
	if (ctx->mpart == NULL) {
	    *plen -= msg - *pmsg;
	    *pmsg = msg;
	    return (0);
	}
	wprintf(NULL, w_fatal, "MIME boundary '%t' not found",
		ctx->mpart->keep[K_BOUNDARY]);
	return (-1);
    }

    /* advance to next part */
    if (*msg == '\r' && msg[1] == '\n') ++msg;
    ++msg, ++ctx->lineno;
    *plen -= msg - *pmsg;
    *pmsg = msg;

    return (1);
}

/* parse a MIME entity
 *  returns 1 on success, 0 on end of message, -1 on fatal error
 */
static int parsemime(msgcontext *ctx, const char **pmsg, int *plen, int htype)
{
    static const char pgpsig[] = "pgp-signature";
    static const char appl[] = "application/";
#define PGPLEN (sizeof (pgpsig) - 1)
#define APPLLEN (sizeof (appl) - 1)
    int r = 0, preamble = 0;
    MIMEinfo *mcur;

    /* loop for nested message/rfc822 parts: */
    for (;;) {
	if (parseheaders(ctx, pmsg, plen, htype) == -1) return (-1);
	MD5Init(&ctx->md5);
	if (htype == HEAD_EXTB) break;
	mcur = ctx->mcur;
	    
	if (!quiet) {
	    if (mcur->keep[K_CTYPE] != NULL &&
		mcur->keep[K_SUBTYPE] != NULL) {
		wprintf(NULL, w_ok, "found part %t/%t line %d",
			mcur->keep[K_CTYPE],
			mcur->keep[K_SUBTYPE], ctx->lineno);
	    } else {
		wprintf(NULL, w_ok, "found default part %s line %d",
			ctx->mpart != NULL && ctx->mpart->indigest ?
			"message/rfc822" : "text/plain", ctx->lineno);
	    }
	}
	
	/* handle subtypes with RFC 822/MIME headers */
	switch (mcur->typenum) {
	  case multipart:
	    preamble = 1;
	    break;

	  case application:
	    if (tokcomp(pgpsig, PGPLEN, mcur->keep[K_SUBTYPE]) == 0 &&
		ctx->mpart->keep[K_PROTO] != NULL &&
		(ctx->mpart->keep[K_PROTO]->len != PGPLEN+APPLLEN ||
		 strncasecmp(appl, ctx->mpart->keep[K_PROTO]->data, APPLLEN) ||
		 strncasecmp(pgpsig, ctx->mpart->keep[K_PROTO]->data
			     + APPLLEN, PGPLEN))) {
		wprintf(NULL, w_error, "mismatch of inner content subtype "
			"'%t' line %d with outer protocol parameter '%t'",
			mcur->keep[K_SUBTYPE], ctx->lineno,
			ctx->mpart->keep[K_PROTO]);
	    }
	    if (tokprefix("octet", 5, mcur->keep[K_SUBTYPE]) == 0 &&
		tokcomp("octet-stream", -1, mcur->keep[K_SUBTYPE]) != 0) {
		wprintf(NULL, w_warn, "possible misspelling of "
		       "'octet-stream' at '%t' in Content-Type header "
		       "before line %d", mcur->keep[K_SUBTYPE],
			ctx->lineno);
	    }
	    break;
	    
	  case message:

	    if (mcur->keep[K_SUBTYPE] == NULL ||
		tokcomp("rfc822", -1, mcur->keep[K_SUBTYPE]) == 0) {
		htype = HEAD_INNER;
		continue;
	    } else if (tokcomp("delivery-status", -1, mcur->keep[K_SUBTYPE])
		       == 0) {
		if (!ctx->mpart || !ctx->mpart->keep[K_REPTYPE]) {
		    wprintf(NULL, w_error, "missing report-type parameter on "
			    "multipart enclosing line %d", ctx->lineno);
		} else if (tokcomp("delivery-status", -1,
				   ctx->mpart->keep[K_REPTYPE]) != 0) {
		    wprintf(NULL, w_error, "mismatch of inner content "
			    "subtype '%t' line %d with outer report-type "
			    "parameter '%t'",
			   mcur->keep[K_SUBTYPE],
			   ctx->lineno,
			   ctx->mpart->keep[K_REPTYPE]);
		}
		r = parseheaders(ctx, pmsg, plen, HEAD_DSN);
		while (r == 0 && *plen > 0 &&
		       **pmsg != '-' && **pmsg != '\0') {
		    r = parseheaders(ctx, pmsg, plen, HEAD_RCPT);
		}
	    } else if (tokcomp("disposition-notification", -1,
			       mcur->keep[K_SUBTYPE])==0) {
		if (!ctx->mpart || !ctx->mpart->keep[K_REPTYPE]) {
		    wprintf(NULL, w_error, "missing report-type parameter on "
			    "multipart enclosing line %d", ctx->lineno);
		} else if (tokcomp("disposition-notification", -1,
				   ctx->mpart->keep[K_REPTYPE]) != 0) {
		    wprintf(NULL, w_error, "mismatch of inner content "
			    "subtype '%t' line %d with outer report-type "
			    "parameter '%t'",
			   mcur->keep[K_SUBTYPE],
			   ctx->lineno,
			   ctx->mpart->keep[K_REPTYPE]);
		}
		r = parseheaders(ctx, pmsg, plen, HEAD_MDN);
	    } else if (tokcomp("tracking-status", -1, mcur->keep[K_SUBTYPE])
		       == 0) {
		if (!ctx->mpart || !ctx->mpart->inrelated) {
		    wprintf(NULL, w_error, "tracking-status should only "
			    "appear in a multipart/related line %d",
			    ctx->lineno);
		} else if (!ctx->mpart->keep[K_RELTYPE]) {
		    wprintf(NULL, w_error, "Missing type parameter on "
			    "multipart enclosing line %d", ctx->lineno);
		} else if (tokcomp("message/tracking-status", -1,
				   ctx->mpart->keep[K_RELTYPE]) != 0) {
		    wprintf(NULL, w_error, "mismatch of inner content "
			    "type 'message/%t' line %d with outer "
			    "multipart/related type parameter '%t'",
			    mcur->keep[K_SUBTYPE],
			    ctx->lineno,
			    ctx->mpart->keep[K_RELTYPE]);
		}
		r = parseheaders(ctx, pmsg, plen, HEAD_MTRKM);
		while (r == 0 && *plen > 0 &&
		       **pmsg != '-' && **pmsg != '\0') {
		    r = parseheaders(ctx, pmsg, plen, HEAD_MTRKR);
		}
	    } else if (tokcomp("external-body", -1, mcur->keep[K_SUBTYPE])
		       == 0) {
		htype = HEAD_EXTB;
		continue;
	    }
	    break;
	    
	  case text:
	    if (mcur->keep[K_SUBTYPE] == NULL ||
	        tokcomp("plain", -1, mcur->keep[K_SUBTYPE]) == 0) {
	        mcur->textplain = 1;
	        if (mcur->keep[K_FORMAT] != NULL &&
	            tokcomp("flowed", -1, mcur->keep[K_FORMAT]) == 0) {
	            mcur->textplain = 2;
	        }
	    } else if (tokcomp("rfc822-headers", -1, mcur->keep[K_SUBTYPE])
		       == 0 &&
		       (mcur->cte == cte7bit || mcur->cte == cte8bit)) {
		r = parseheaders(ctx, pmsg, plen, HEAD_TEXT);
	    }
	    break;
	}
	if (r == -1) return (-1);
	break;
    }

    return (findboundary(ctx, pmsg, plen, preamble));
}

/* parse a message
 */
int parsemessage(const char *msg, int len)
{
    const char *fullmsg, *endmsg;
    msgcontext ctx;
    int r, htype, saw8bit, mlen;
    unsigned long bound, pid;
    char dbuf[N_MDATELEN];
    char hostname[1024];

    saw8bit = 0;
    fullmsg = msg;
    mlen = len;
    endmsg = msg + len;
    
    ctx.mcur = NULL;
    ctx.mpart = NULL;
    ctx.lineno = 1;
    ctx.lines = 0;
    ctx.endhead = 0;

    if (web_cgi) {
	fprintf(outfile, "Content-Type: text/plain\n\n");
    }
    
    if (mime_msg) {
	reply_line = NULL;
	reply_len = 0;
	r = silent;
	silent = 1;
	parseheaders(&ctx, &msg, &len, HEAD_MSG);
	silent = r;
	if (reply_line == NULL && do_sendmail) return (-1);
    }
    
    if (outfile == NULL) {
	outfile = popen("/usr/lib/sendmail -t -oi", "w");
	if (outfile == NULL) return (-1);
    }

    if (mime_msg) {
	/* check for 8 bit (not efficient, but simple) */
	while (msg < endmsg && (unsigned char) *msg < 0x80)
	    ++msg;
	if (msg < endmsg) saw8bit = 1;
	msg = fullmsg;

	/* get system params */
	gethostname(hostname, sizeof (hostname));
	bound = time(0);
	pid = getpid();
	n_maildate(dbuf);
	fprintf(outfile, "Date: %s\n", dbuf);
	if (from_addr != NULL) {
	    fprintf(outfile, "From: %s\n", from_addr);
	}
	fprintf(outfile, "Subject: validation of your message\n");
	ctx.lineno = 1;
	msg = fullmsg;
	len = mlen;
	disposeminfo(ctx.mcur);
	ctx.mcur = NULL;
	if (reply_line != NULL) {
	    wprintf(NULL, "To: ", "%.*s", reply_len, reply_line);
	}
	fprintf(outfile, "MIME-Version: 1.0\n");
	wprintf(NULL, "Content-Type: ",
		"multipart/mixed; boundary=\"%lx=_%lx\"", bound, pid);
	if (saw8bit) {
	    fprintf(outfile, "Content-Transfer-Encoding: 8bit\n");
	}
	fprintf(outfile, "Message-ID: <mimelint.%lx.%lx@%s>\n",
                bound, pid, hostname);
	fprintf(outfile, "\n");
	fprintf(outfile, "--%lx=_%lx\n", bound, pid);
	fprintf(outfile, "\n");
    }
    
    if (web_cgi || mime_msg) {
	wprintf(NULL, w_none, text_para1, version);
	fprintf(outfile, "\n");
	fprintf(outfile, "-----------\n");
    }
    
    for (htype = HEAD_MSG;
	 (r = parsemime(&ctx, &msg, &len, htype)) == 1;
	 htype = HEAD_MIME)
	;
    if (ctx.lines) {
	if (ctx.lineno - ctx.endhead != ctx.lines) {
	    wprintf(NULL, w_warn, "'Lines' header value %d doesn't match "
		    "actual lines in body (%d)",
		    ctx.lines, ctx.lineno - ctx.endhead);
	} else if (!quiet) {
	    wprintf(NULL, w_ok, "Validated 'Lines' header (%d lines in body)",
		    ctx.lines);
	}
    }
    if (verbose) {
	wprintf(NULL, w_ok, "scanned %d lines", ctx.lineno - 1);
    }

    if (mime_msg || web_cgi) {
	fprintf(outfile, "-----------\n");
	fprintf(outfile, "\n");
	wprintf(NULL, w_none, text_para2, version);
	fprintf(outfile, "\n");
	wprintf(NULL, w_none, text_para3);
    }

    if (mime_msg) {
	fprintf(outfile, "\n");
	wprintf(NULL, w_none, text_para4);
	fprintf(outfile, "\n");
	fprintf(outfile, "--%lx=_%lx\n", bound, pid);
	fprintf(outfile, "Content-Type: message/rfc822\n");
	if (saw8bit) {
	    fprintf(outfile, "Content-Transfer-Encoding: 8bit\n");
	}
	fprintf(outfile, "\n");
    }

    if (web_cgi) {
	fprintf(outfile, "\n");
	fprintf(outfile, "Input message follows:\n");
	fprintf(outfile, "-----------\n");
    }

    if (mime_msg || web_cgi) {
	fprintf(outfile, "%.*s\n", mlen, fullmsg);
    }

    if (mime_msg) {
	fprintf(outfile, "--%lx=_%lx--\n", bound, pid);
    }

    if (outfile != stdout) {
	r = pclose(outfile);
	outfile = NULL;
    }
    
    return (r);
}

static void usage(const char *name)
{
    fprintf(stderr, "Usage: %s [-v] [-q] [-m] [-s] [filename]\n", name);
    fprintf(stderr, "  -v              verbose output\n");
    fprintf(stderr, "  -q              quiet output\n");
    fprintf(stderr, "  -s              silent output\n");
    fprintf(stderr, "  -t              pass output to sendmail -t (ignored without -f/-m)\n");
    fprintf(stderr, "  -m              MIME-style output\n");
    fprintf(stderr, "  -5              Show MD5 of body parts\n");
    fprintf(stderr, "  -f <fromaddr>   The from address for replies (implies -m)\n");
    exit(1);
}

int main(int argc, char **argv)
{
    const unsigned char *uscan;
    unsigned char uc;
    int r = 0;
    const char *name;
    char *buf, *basebuf, *src, *dst;
    size_t used, count, unused;
    FILE *infile = stdin;

    (void) argc;
    
    /* initialize special table */
    memset(special_table, 0, sizeof (special_table));
    for (uscan = specials; *uscan; ++uscan) {
	special_table[(unsigned) *uscan] = SPECIAL_BIT;
    }
    for (uscan = tspecials; *uscan; ++uscan) {
	special_table[(unsigned) *uscan] |= TSPECIAL_BIT;
    }
    for (uscan = bspecials; *uscan; ++uscan) {
	special_table[(unsigned) *uscan] |= BSPECIAL_BIT;
    }
    for (uc = 'A'; uc <= 'Z'; ++uc) {
	special_table[uc] |= BSPECIAL_BIT;
	special_table[TOLOWER(uc)] |= BSPECIAL_BIT;
    }
    memset(hex_table, 16, sizeof (hex_table));
    for (uscan = hexchars; *uscan; ++uscan) {
	hex_table[(unsigned) *uscan] = uscan - hexchars;
    }

    name = strrchr(*argv, '/');
    name = name == NULL ? *argv : name + 1;
    if (strncmp("web", name, 3) == 0
	|| getenv("GATEWAY_INTERFACE") != (char *)0)
	web_cgi = 1;
    
    /* parse args */
    while (*++argv != NULL && **argv == '-') switch ((*argv)[1]) {
      case 'v':
	verbose = 1;
	break;

      case 'w':
	web_cgi = 1;
	break;

      case '5':
	show_md5 = 1;
	break;

      case 'm':
	mime_msg = 1;
	break;

      case 't':
	do_sendmail = 1;
	break;

      case 'q':
	quiet = 1;
	break;

      case 's':
	silent = 1;
	break;

      case 'f':
	if (argv[1] != NULL) {
	    from_addr = *++argv;
	    mime_msg = 1;
	}
	break;

      default:
	usage(name);
    }
    if (!do_sendmail || !mime_msg) {
	outfile = stdout;
    }
    
    do {
	if (*argv != NULL) {
	    if (outfile != NULL && (infile != stdin || argv[1] != NULL)) {
		fprintf(outfile, "---%s\n", *argv);
	    }
	    infile = fopen(*argv, "r");
	    if (infile == NULL) {
		perror(*argv);
		exit(1);
	    }
	    ++argv;
	}
    
	/* read in the data */
	basebuf = buf = malloc(unused = BUFSIZE);
	if (buf == NULL) {
	    perror("malloc");
	    exit(1);
	}
	used = 0;
	while ((count = fread(buf + used, 1, unused, infile)) > 0) {
	    used += count;
	    unused -= count;
	    if (unused <= 0) {
		basebuf = buf = realloc(buf, used * 2);
		if (buf == NULL) {
		    perror("realloc");
		    exit(1);
		}
		unused += used;
	    }
	}
	buf[used] = '\0';
	if (infile != stdin) fclose(infile);
	
	/* remove web CGI grunge */
	if (web_cgi) {
	    for (src = buf; *src != '\0' && !isspace(*src) &&
		 *src != ':' && *src != '='; ++src)
		;
	    if (*src == '=') {
		++src;
		for (dst = buf; *src != '&' && *src != '\0'; ++src, ++dst) {
		    if (*src == '%') {
			*dst = (hex_table[(unsigned char)src[1]] << 4) +
			    hex_table[(unsigned char)src[2]];
			src += 2;
		    } else if (*src == '+') {
			*dst = ' ';
		    } else {
			*dst = *src;
		    }
		}
		*dst = '\0';
		used = dst - buf;
	    }
	} else if (used > 5 && strncmp(buf, "From ", 5) == 0) {
	    /* remove "From " grunge */
	    while (used > 0 && *buf != '\n' && *buf != '\r') {
		--used, ++buf;
	    }
	    while (used > 0 && (*buf == '\n' || *buf == '\r')) {
		--used, ++buf;
	    }
	}
	
	/* parse the data */
	if (verbose) wprintf(NULL, w_ok, "read message of size %d", used);

	r = parsemessage(buf, used);

	/* close file */
	if (infile != stdin) fclose(infile);

	/* release buffer */
	free(basebuf);
    } while (r == 0 && *argv != NULL);

    return (r);
}
