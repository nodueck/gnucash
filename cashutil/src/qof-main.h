/***************************************************************************
 *            qof-main.h
 *
 *  This is an auto-generated file. Patches are available from
 *  http://qof-gen.sourceforge.net/
 *
 *  Thu Jan 13 12:15:41 2005
 *  Copyright  2005  Neil Williams
 *  linux@codehelp.co.uk
 ****************************************************************************/
/*
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
 */
/** @addtogroup QOFCLI Query Object Framework Command Line Interface.

QOF provides an outline CLI that is easily patched
from the qof-generator project to make it easier
to keep various QOF projects updated.

This CLI is easily extended to support your own functions
and options and includes macros to help you keep up to date
with changes in main QOF options. It is recommended that you
do not edit this file, instead please feed patches back to the
QOF-devel mailing list at
http://lists.sourceforge.net/mailman/listinfo/qof-devel
so that other projects can be updated.

@{
*/
/** @file qof-main.h
  @brief Common functions for the QOF external framework
  @author Copyright (c) 2005 Neil Williams <linux@codehelp.co.uk>
*/

#ifndef _QOF_MAIN_H
#define _QOF_MAIN_H
#include <qof.h>
#include <stdlib.h>
#include <time.h>
#include <popt.h>

#if defined(HAVE_GETTEXT)             /* HAVE_GETTEXT */

#include <libintl.h>
#include <locale.h>

#undef _
#undef Q_

#ifdef DISABLE_GETTEXT_UNDERSCORE
#define _(String) (String)
#define Q_(String) gnc_qualifier_prefix_noop(String)
#else                                 /* ENABLE_GETTEXT_UNDERSCORE */
#define _(String) gettext(String)
#define Q_(String) gnc_qualifier_prefix_gettext(String)
#endif                                /* End ENABLE_GETTEXT_UNDERSCORE */

#else                                 /* Not HAVE_GETTEXT */
#if !defined(__USE_GNU_GETTEXT)

#undef _
#undef Q_
#define _(String)       (String)
#define Q_(String) gnc_qualifier_prefix_noop(String)
#define gettext(String) (String)
#define ngettext(msgid, msgid_plural, n) (((n)==1) ? \
                                            (msgid) : (msgid_plural))

#endif                                /* End not__USE_GNU_GETTEXT */
#endif                                /* End Not HAVE_GETTEXT */

#undef  N_
#define N_(String) (String)

/** \brief List of all parameters for this object of one QOF type. 

Return a GSList of all parameters of this object that are a
particular QOF type, QOF_TYPE_STRING, QOF_TYPE_BOOLEAN etc.

The returned GSList should be freed by the caller.

\note The return list is a singly linked list - GSList -
\b not the doubly-linked list - GList - returned by 
::qof_class_get_referenceList.

\param object_type  object->e_type for the relevant object.
\param param_type  The type of parameter to match, QOF_TYPE_STRING etc.

\return GSList of all matching parameters or NULL if none exist.
*/
GSList*
qof_main_get_param_list(QofIdTypeConst object_type, QofType param_type);

/** Maximum length of the UTC timestamp used by QSF

QOF_UTC_DATE_FORMAT   "%Y-%m-%dT%H:%M:%SZ"
*/
#define QOF_DATE_STRING_LENGTH  MAX_DATE_LENGTH

/** Debug module for qof-main */
#define QOF_MAIN_CLI  "QOF-mod-command-line"

/** \brief Category name.

The name of the parameter that holds the category of the entity.

Many CLI data sources categorise data by user-editable category
strings. If your program does not, simply implement a modified
QOF_CLI_OPTIONS in your code without the category option:
\verbatim
{"category", 'c', POPT_ARG_STRING, &category, qof_op_category,
_("Shorthand to only query objects that are set to the specified category."),
"string"},
\endverbatim
*/
#define CATEGORY_NAME "category"

/** backend configuration index string for QSF

The identifier for the configuration option within
QSF supported by the CLI. Matches the
QofBackendOption->option_name in the KvpFrame
holding the options.
*/
#define QSF_COMPRESS "compression_level"

/** The SQL commands supported by QOF

A regular expression used to exclude unsupported commands
from SQL files. Anything that does \b not match the expression
will be silently ignored. This allows genuine
SQL dump files to be parsed without errors.

 A QOF object is similar to a definition of a SQL table.\n
 A QOF entity is similar to an instance of a SQL record.\n
 A QOF parameter is similar to data in a SQL field.

Certain SQL commands have no QOF equivalent and should
always be ignored silently:
 - ALTER (the object parameters cannot be changed at runtime)
 - CREATE (new tables - new objects - cannot be created at runtime)
 - DROP  (an object cannot be "de-registered" without re-compiling)
 - FLUSH (QOF has no permissions system)
 - GRANT
 - KILL
 - LOCK
 - OPTIMIZE
 - REVOKE
 - USE (QOF only has one database, itself.)
*/
#define QOF_SQL_SUPPORTED  "^SELECT|INSERT"

/** \brief Output error messages from QOF

QOF will set errors in the QofSession. The
application determines how to output those
messages and for the CLI, this will be to
stderr. Not all these messages are implemented
in any one QOF CLI.

\param session Any current session.
*/
void qof_main_show_error(QofSession *session);

/** \brief The qof-main context struct.

Intended as a core type for QOF-based CLI programs, wrap
your own context struct around qof_main_context
*/
typedef struct qof_main_s {
	gchar *filename;		    /**< Input filename containing QSF XML data, if any.*/
	gchar *write_file; 		    /**< Export filename, if any.*/
	gchar *input_file;		    /**< File containing data to upload, if any. */
	gchar *sql_file;		    /**< SQL file, if any. */
	gchar *sql_str;			    /**< The current SQL, overwritten each iteration
								if using a file.*/
	gchar *database;		    /**< The database to include with -d. */
	gchar *exclude;			    /**< The database to exclude with -e. */
	gchar *category;		    /**< The category to include with -c.*/
	Timespec min_ts;		    /**< Holds the converted -t field - minimum.
								Matches objects above min. */
	Timespec max_ts;		    /**< Holds the converted -t field - maximum.
								Matches objects below max. */
	QofSession *input_session;  /**< The input session - hotsync or offline storage. */
	QofSession *export_session; /**< The query results session, for STDOUT or -w,
								both as QSF XML. */
	gboolean error;             /**< general error, abort. */
    QofQuery *query;            /**< The current QofQuery, converted from QofSqlQuery */
	GList *sql_list;            /**< List of sql commands from a file. */
	gint gz_level;              /**< Use compression (>0 <=9) or not (0)*/
}qof_main_context;

/** Free qof_main_context values when work is done. */
void qof_main_free (qof_main_context *context);

/** \brief Check that the SQL command is supported.*/
gboolean qof_check_sql(const char *sql);

/** \enum qof_op_type

main operator enum
*/
/** \enum qof_op_type::qof_op_noop

undefined check value
*/
/**\enum qof_op_type::qof_op_input

execute input command
*/
/** \enum qof_op_type::qof_op_list

List supported databases command.
*/
/** \enum qof_op_type::qof_op_category

Shorthand category option.
*/

/** query the QSF XML data */
void qof_cmd_xmlfile (qof_main_context *context);

/** \brief Lists all databases supported by the current QOF framework.

Prints the name and description for each object type
registered with this instance of QOF. No options are used.
*/
void qof_cmd_list (void);

/** \brief Shorthand to only query objects that are set to the specified category.

Modifies the QOF query to only query objects that are set to
\a category.
*/
void qof_mod_category (const char *category, qof_main_context *data);

/** \brief Shorthand to only query objects within one specific supported database.

Used to only query objects within the specified
database.
*/
void qof_mod_database (const char *database, qof_main_context *data);

/** \brief Shorthand to only query objects that contain the specified date.

Used to modify the QOF query to only query objects that contain
at least one parameter containing a QOF_TYPE_DATE that
matches the range specified. Dates need to be specified as YY-MM-DD.

You can specify a UTC timestring, just as normally output by QSF,
but the time will not be matched when using the shorthand option,
only the year, month and day.

For more precise time matches or to set a defined period that doesn't follow
whole calendar months, (e.g. the UK financial year) use a SQL statement:

"SELECT * from pilot_datebook where start_time > '2004-04-06T00:00Z'\n
and end_time < '2005-04-05T23:59:59Z';"

Partial matches are allowed, so YY-MM matches
any object where a date is within the specified month and year,
YY matches any object where a date is within the specified year.

The query range starts at midnight on the first day of the range
and ends at 1 second to midnight on the last day of the range.
*/
void qof_mod_timespec (const char *date_time, qof_main_context *data);

/** \brief Shorthand to exclude a supported database from the query.

Excludes the (single) specified database from the query.
*/
void qof_mod_exclude (const char *exclude, qof_main_context *data);

/** \brief Specify a SQL query on the command line.

For SELECT, the returned list is a list of all of the instances of 'SomeObj' that
match the query. The 'SORT' term is optional. The 'WHERE' term is optional; but
if you don't include 'WHERE', you will get a list of all of the object instances.
The Boolean operations 'AND' and 'OR' together with parenthesis can be used to construct
arbitrarily nested predicates.

For INSERT, the returned list is a list containing the newly created instance of 'SomeObj'.

Date queries handle full date and time strings, using the format exported by the QSF
backend. To query dates and times, convert user input into UTC time using the
QOF_UTC_DATE_FORMAT string. e.g. set the UTC date format and call qof_print_time_buff
with a time_t obtained via timespecToTime_t.

If the param is a KVP frame, then we use a special markup to indicate frame values.
The markup should look like /some/kvp/path:value. Thus, for example,\n
SELECT * FROM SomeObj WHERE (param_a < '/some/kvp:10.0')\n
will search for the object where param_a is a KVP frame, and this KVP frame contains
a path '/some/kvp' and the value stored at that path is floating-point and that float
value is less than 10.0.

*/
void qof_mod_sql (const char *sql_query, qof_main_context *data);

/** \brief Specify one or more SQL queries contained in a file.

The rules for single SQL commands also apply with regard to the lack of explicit
support for joins and the pending support for selecting only certain parameters
from a certain object.

See ::qof_mod_sql for information on the queries supported.

\note Where possible, this function uses the safer GNU extension: getline().
On Mac OSX and other platforms that do not provide getline, the call uses
the less reliable fgets(). If the input file contains a NULL, fgets will
get confused and the read may terminate early on such platforms.\n
http://www.gnu.org/software/libc/manual/html_node/Line-Input.html

*/
void qof_mod_sql_file (const char *sql_file, qof_main_context *data);

/** \brief Write the results of any query to the file

\a filename of the file to be written out using the QSF XML
QofBackend.

*/
void qof_mod_write (const char *write_file, qof_main_context *data);

/** Pass the requested compression to QSF

@param gz_level Integer between 0 and 9, 9 highest compression, 0 for none.
*/
void
qof_mod_compression (gint gz_level, qof_main_context *context);

/** \brief Assemble the components of the query.

If any SQL statements are found, run
separately from any -c, -d or -t options.

All queries are additive: Successive queries add
more entities to the result set but no entity is
set more than once.
*/
void
qof_main_moderate_query(qof_main_context *context);

/** Print a list of available parameters for a database.

Used with qof_mod_database to print a list of
QofParam for the QofObject set in context->database.
*/
void
qof_cmd_explain (qof_main_context *context);

void qof_main_select(qof_main_context *context);

/** \brief Common QOF CLI options
 *
 * These are definitions for popt support in the CLI. Every program's
 * popt table should start with QOF_CLI_OPTIONS or a replacement to insert
 * the standard options into it. Also enables autohelp. End your
 * popt option list with POPT_TABLEEND. If you want to remove any
 * of these options, simply copy QOF_CLI_OPTIONS into a macro of
 * your own and remove the options you do not need.
*/
#define QOF_CLI_OPTIONS POPT_AUTOHELP \
	{"list", 'l', POPT_ARG_NONE, NULL, qof_op_list, \
	 _("List all databases supported by the current QOF framework and exit."), \
	 NULL}, \
	{"explain", 0, POPT_ARG_NONE, NULL, qof_op_explain, \
	 _("List the fields within the specified database and exit, requires -d."), \
	 NULL}, \
	{"xml-file", 'x', POPT_ARG_STRING, &filename, qof_op_xmlfile, \
	_("Query the QSF XML data in <filename>"), \
	"filename"}, \
	{"date", 't', POPT_ARG_STRING, &date_time, qof_op_timespec, \
	 _("Shorthand to only query objects that contain the specified date."), \
	 "string"}, \
	{"database", 'd', POPT_ARG_STRING, &database, qof_op_database, \
	 _("Shorthand to only query objects within a specific supported database. "), \
	 "string"}, \
	{"exclude", 'e', POPT_ARG_STRING, &exclude, qof_op_exclude, \
	 _("Shorthand to exclude a supported database from the query."), \
	 "string"}, \
	{"sql", 's', POPT_ARG_STRING, &sql_query, qof_op_sql, \
	 _("Specify a SQL query on the command line."), "string"}, \
	{"sql-file", 'f', POPT_ARG_STRING, &sql_file, qof_op_sql_file, \
	 _("Specify one or more SQL queries contained in a file."), \
	 "filename"}, \
	{"write", 'w', POPT_ARG_STRING, &write_file, qof_op_write, \
	 _("Write the results of any query to the file"), "filename"}, \
	{"compress", 0, POPT_ARG_INT, &gz_level, qof_op_compress, \
	 _("Compress output files, 0 for none, 9 for maximum"), "integer"}, \
	{"debug", 0, POPT_ARG_NONE, NULL, qof_op_debug, \
	 _("Print debugging information to a temporary file."), NULL}, \
	{"version", 0, POPT_ARG_NONE, NULL, qof_op_vers, \
	 _("Display version information"), NULL}, \
    {"category", 'c', POPT_ARG_STRING, &category, qof_op_category, \
     _("Shorthand to only query objects that are set to the specified category."), \
     "string"},


/** use only if you have no extended options, otherwise use as a template. */
#define QOF_MAIN_OP \
 	_(qof_op_noop, = 0) \
	_(qof_op_list,)     \
	_(qof_op_xmlfile,)  \
	_(qof_op_category,) \
	_(qof_op_database,) \
	_(qof_op_timespec,) \
	_(qof_op_exclude,)  \
	_(qof_op_sql,)      \
	_(qof_op_sql_file,) \
	_(qof_op_write, )   \
	_(qof_op_explain,)  \
	_(qof_op_vers,)     \
	_(qof_op_compress,) \
	_(qof_op_debug,)

/** Define the variables for the standard QOF CLI options.

If you remove any QOF CLI options, ensure you also remove
the option variable and it's initialiser.
*/
#define QOF_OP_VARS \
       const char *exclude,  *date_time,  *category,  *database; \
       const char *sql_file, *write_file, *sql_query, *filename;

/** initialise the standard QOF CLI option variables.

A simple convenience macro.
*/
#define QOF_OP_INIT    \
       exclude = NULL;    \
       category = NULL;   \
       database = NULL;   \
       sql_file = NULL;   \
       write_file = NULL; \
       sql_query = NULL;  \
       filename = NULL;
/** @} */
/** @} */

#endif				/* _QOF_MAIN_H */
