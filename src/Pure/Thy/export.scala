/*  Title:      Pure/Thy/export.scala
    Author:     Makarius

Manage theory exports: compressed blobs.
*/

package isabelle


import scala.annotation.tailrec
import scala.util.matching.Regex


object Export {
  /* artefact names */

  val DOCUMENT_ID = "PIDE/document_id"
  val FILES = "PIDE/files"
  val MARKUP = "PIDE/markup"
  val MESSAGES = "PIDE/messages"
  val DOCUMENT_PREFIX = "document/"
  val DOCUMENT_LATEX = DOCUMENT_PREFIX + "latex"
  val THEORY_PREFIX: String = "theory/"
  val PROOFS_PREFIX: String = "proofs/"

  def explode_name(s: String): List[String] = space_explode('/', s)
  def implode_name(elems: Iterable[String]): String = elems.mkString("/")


  /* SQL data model */

  object Data {
    val session_name = SQL.Column.string("session_name").make_primary_key
    val theory_name = SQL.Column.string("theory_name").make_primary_key
    val name = SQL.Column.string("name").make_primary_key
    val executable = SQL.Column.bool("executable")
    val compressed = SQL.Column.bool("compressed")
    val body = SQL.Column.bytes("body")

    val table =
      SQL.Table("isabelle_exports",
        List(session_name, theory_name, name, executable, compressed, body))

    val tables = SQL.Tables(table)

    def where_equal(session_name: String, theory_name: String = "", name: String = ""): SQL.Source =
      SQL.where_and(
        Data.session_name.equal(session_name),
        if_proper(theory_name, Data.theory_name.equal(theory_name)),
        if_proper(name, Data.name.equal(name)))
  }

  def compound_name(a: String, b: String): String =
    if (a.isEmpty) b else a + ":" + b

  sealed case class Entry_Name(session: String = "", theory: String = "", name: String = "") {
    val compound_name: String = Export.compound_name(theory, name)

    def make_path(prune: Int = 0): Path = {
      val elems = theory :: space_explode('/', name)
      if (elems.length < prune + 1) {
        error("Cannot prune path by " + prune + " element(s): " + Path.make(elems))
      }
      else Path.make(elems.drop(prune))
    }

    def readable(db: SQL.Database): Boolean = {
      db.execute_query_statementB(
        Data.table.select(List(Data.name),
          sql = Data.where_equal(session, theory, name)))
    }

    def read(db: SQL.Database, cache: XML.Cache): Option[Entry] =
      db.execute_query_statementO[Entry](
        Data.table.select(List(Data.executable, Data.compressed, Data.body),
          sql = Data.where_equal(session, theory, name)),
        { res =>
          val executable = res.bool(Data.executable)
          val compressed = res.bool(Data.compressed)
          val bytes = res.bytes(Data.body)
          val body = Future.value(compressed, bytes)
          Entry(this, executable, body, cache)
        }
      )
  }

  def read_theory_names(db: SQL.Database, session_name: String): List[String] =
    db.execute_query_statement(
      Data.table.select(List(Data.theory_name), distinct = true,
        sql = Data.where_equal(session_name) + SQL.order_by(List(Data.theory_name))),
      List.from[String], res => res.string(Data.theory_name))

  def read_entry_names(db: SQL.Database, session_name: String): List[Entry_Name] =
    db.execute_query_statement(
      Data.table.select(List(Data.theory_name, Data.name),
        sql = Data.where_equal(session_name)) + SQL.order_by(List(Data.theory_name, Data.name)),
      List.from[Entry_Name],
      { res =>
        Entry_Name(
          session = session_name,
          theory = res.string(Data.theory_name),
          name = res.string(Data.name))
      })

  def message(msg: String, theory_name: String, name: String): String =
    msg + " " + quote(name) + " for theory " + quote(theory_name)

  object Entry {
    def apply(
      entry_name: Entry_Name,
      executable: Boolean,
      body: Future[(Boolean, Bytes)],
      cache: XML.Cache
    ): Entry = new Entry(entry_name, executable, body, cache)

    def empty(theory_name: String, name: String): Entry =
      Entry(Entry_Name(theory = theory_name, name = name),
        false, Future.value(false, Bytes.empty), XML.Cache.none)

    def make(
      session_name: String,
      args: Protocol.Export.Args,
      bytes: Bytes,
      cache: XML.Cache
    ): Entry = {
      val body =
        if (args.compress) Future.fork(bytes.maybe_compress(cache = cache.compress))
        else Future.value((false, bytes))
      val entry_name =
        Entry_Name(session = session_name, theory = args.theory_name, name = args.name)
      Entry(entry_name, args.executable, body, cache)
    }
  }

  final class Entry private(
    val entry_name: Entry_Name,
    val executable: Boolean,
    body: Future[(Boolean, Bytes)],
    cache: XML.Cache
  ) {
    def session_name: String = entry_name.session
    def theory_name: String = entry_name.theory
    def name: String = entry_name.name
    override def toString: String = name

    def is_finished: Boolean = body.is_finished
    def cancel(): Unit = body.cancel()

    def compound_name: String = entry_name.compound_name

    def name_has_prefix(s: String): Boolean = name.startsWith(s)
    val name_elems: List[String] = explode_name(name)

    def name_extends(elems: List[String]): Boolean =
      name_elems.startsWith(elems) && name_elems != elems

    def bytes: Bytes = {
      val (compressed, bs) = body.join
      if (compressed) bs.uncompress(cache = cache.compress) else bs
    }

    def text: String = bytes.text

    def yxml: XML.Body = YXML.parse_body(UTF8.decode_permissive(bytes), cache = cache)

    def write(db: SQL.Database): Unit = {
      val (compressed, bs) = body.join
      db.execute_statement(Data.table.insert(), body =
        { stmt =>
          stmt.string(1) = session_name
          stmt.string(2) = theory_name
          stmt.string(3) = name
          stmt.bool(4) = executable
          stmt.bool(5) = compressed
          stmt.bytes(6) = bs
        })
    }
  }

  def make_regex(pattern: String): Regex = {
    @tailrec def make(result: List[String], depth: Int, chs: List[Char]): Regex =
      chs match {
        case '*' :: '*' :: rest => make("[^:]*" :: result, depth, rest)
        case '*' :: rest => make("[^:/]*" :: result, depth, rest)
        case '?' :: rest => make("[^:/]" :: result, depth, rest)
        case '\\' :: c :: rest => make(("\\" + c) :: result, depth, rest)
        case '{' :: rest => make("(" :: result, depth + 1, rest)
        case ',' :: rest if depth > 0 => make("|" :: result, depth, rest)
        case '}' :: rest if depth > 0 => make(")" :: result, depth - 1, rest)
        case c :: rest if ".+()".contains(c) => make(("\\" + c) :: result, depth, rest)
        case c :: rest => make(c.toString :: result, depth, rest)
        case Nil => result.reverse.mkString.r
      }
    make(Nil, 0, pattern.toList)
  }

  def make_matcher(pats: List[String]): Entry_Name => Boolean = {
    val regs = pats.map(make_regex)
    (entry_name: Entry_Name) => regs.exists(_.matches(entry_name.compound_name))
  }


  /* database consumer thread */

  def consumer(db: SQL.Database, cache: XML.Cache, progress: Progress = new Progress): Consumer =
    new Consumer(db, cache, progress)

  class Consumer private[Export](db: SQL.Database, cache: XML.Cache, progress: Progress) {
    private val errors = Synchronized[List[String]](Nil)

    private val consumer =
      Consumer_Thread.fork_bulk[(Entry, Boolean)](name = "export")(
        bulk = { case (entry, _) => entry.is_finished },
        consume =
          { (args: List[(Entry, Boolean)]) =>
            val results =
              db.transaction {
                for ((entry, strict) <- args)
                yield {
                  if (progress.stopped) {
                    entry.cancel()
                    Exn.Res(())
                  }
                  else if (entry.entry_name.readable(db)) {
                    if (strict) {
                      val msg = message("Duplicate export", entry.theory_name, entry.name)
                      errors.change(msg :: _)
                    }
                    Exn.Res(())
                  }
                  else Exn.capture { entry.write(db) }
                }
              }
            (results, true)
          })

    def make_entry(session_name: String, args: Protocol.Export.Args, body: Bytes): Unit = {
      if (!progress.stopped && !body.is_empty) {
        consumer.send(Entry.make(session_name, args, body, cache) -> args.strict)
      }
    }

    def shutdown(close: Boolean = false): List[String] = {
      consumer.shutdown()
      if (close) db.close()
      errors.value.reverse ::: (if (progress.stopped) List("Export stopped") else Nil)
    }
  }


  /* context for database access */

  def open_database_context(store: Store): Database_Context = {
    val database_server = if (store.build_database_server) Some(store.open_database_server()) else None
    new Database_Context(store, database_server)
  }

  def open_session_context0(store: Store, session: String): Session_Context =
    open_database_context(store).open_session0(session, close_database_context = true)

  def open_session_context(
    store: Store,
    session_background: Sessions.Background,
    document_snapshot: Option[Document.Snapshot] = None
  ): Session_Context = {
    open_database_context(store).open_session(
      session_background, document_snapshot = document_snapshot, close_database_context = true)
  }

  class Database_Context private[Export](
    val store: Store,
    val database_server: Option[SQL.Database]
  ) extends AutoCloseable {
    database_context =>

    override def toString: String = {
      val s =
        database_server match {
          case Some(db) => db.toString
          case None => "input_dirs = " + store.input_dirs.map(_.absolute).mkString(", ")
        }
      "Database_Context(" + s + ")"
    }

    def cache: Term.Cache = store.cache

    def close(): Unit = database_server.foreach(_.close())

    def open_database(session: String, output: Boolean = false): Session_Database =
      database_server match {
        case Some(db) => new Session_Database(session, db)
        case None =>
          new Session_Database(session, store.open_database(session, output = output)) {
            override def close(): Unit = db.close()
          }
      }

    def open_session0(session: String, close_database_context: Boolean = false): Session_Context =
      open_session(Sessions.background0(session), close_database_context = close_database_context)

    def open_session(
      session_background: Sessions.Background,
      document_snapshot: Option[Document.Snapshot] = None,
      close_database_context: Boolean = false
    ): Session_Context = {
      val session_name = session_background.check_errors.session_name
      val session_hierarchy = session_background.sessions_structure.build_hierarchy(session_name)
      val session_databases =
        database_server match {
          case Some(db) => session_hierarchy.map(name => new Session_Database(name, db))
          case None =>
            val attempts =
              session_hierarchy.map(name => name -> store.try_open_database(name, server = false))
            attempts.collectFirst({ case (name, None) => name }) match {
              case Some(bad) =>
                for ((_, Some(db)) <- attempts) db.close()
                store.error_database(bad)
              case None =>
                for ((name, Some(db)) <- attempts) yield {
                  new Session_Database(name, db) { override def close(): Unit = this.db.close() }
                }
            }
        }
      new Session_Context(
          database_context, session_background, session_databases, document_snapshot) {
        override def close(): Unit = {
          session_databases.foreach(_.close())
          if (close_database_context) database_context.close()
        }
      }
    }
  }

  class Session_Database private[Export](val session: String, val db: SQL.Database)
  extends AutoCloseable {
    def close(): Unit = ()

    lazy private [Export] val theory_names: List[String] = read_theory_names(db, session)
    lazy private [Export] val entry_names: List[Entry_Name] = read_entry_names(db, session)
  }

  class Session_Context private[Export](
    val database_context: Database_Context,
    session_background: Sessions.Background,
    db_hierarchy: List[Session_Database],
    val document_snapshot: Option[Document.Snapshot]
  ) extends AutoCloseable {
    session_context =>

    def close(): Unit = ()

    def cache: Term.Cache = database_context.cache

    def sessions_structure: Sessions.Structure = session_background.sessions_structure

    def session_base: Sessions.Base = session_background.base

    def session_name: String =
      if (document_snapshot.isDefined) Sessions.DRAFT
      else session_base.session_name

    def session_database(session: String = session_name): Option[Session_Database] =
      db_hierarchy.find(_.session == session)

    def session_db(session: String = session_name): Option[SQL.Database] =
      session_database(session = session).map(_.db)

    def session_stack: List[String] =
      ((if (document_snapshot.isDefined) List(session_name) else Nil) :::
        db_hierarchy.map(_.session)).reverse

    private def select[A](
      session: String,
      select: Session_Database => List[A],
      project: Entry_Name => A,
      sort_key: A => String
    ): List[A] = {
      def result(name: String): List[A] =
        if (name == Sessions.DRAFT) {
          (for {
            snapshot <- document_snapshot.iterator
            entry_name <- snapshot.all_exports.keysIterator
          } yield project(entry_name)).toSet.toList.sortBy(sort_key)
        }
        else session_database(name).map(select).getOrElse(Nil)

      if (session.nonEmpty) result(session) else session_stack.flatMap(result)
    }

    def entry_names(session: String = session_name): List[Entry_Name] =
      select(session, _.entry_names, identity, _.compound_name)

    def theory_names(session: String = session_name): List[String] =
      select(session, _.theory_names, _.theory, identity)

    def get(theory: String, name: String): Option[Entry] =
    {
      def snapshot_entry: Option[Entry] =
        for {
          snapshot <- document_snapshot
          entry_name = Entry_Name(session = Sessions.DRAFT, theory = theory, name = name)
          entry <- snapshot.all_exports.get(entry_name)
        } yield entry
      def db_entry: Option[Entry] =
        db_hierarchy.view.map(database =>
          Export.Entry_Name(session = database.session, theory = theory, name = name)
            .read(database.db, cache))
          .collectFirst({ case Some(entry) => entry })

      snapshot_entry orElse db_entry
    }

    def apply(theory: String, name: String, permissive: Boolean = false): Entry =
      get(theory, name) match {
        case None if permissive => Entry.empty(theory, name)
        case None => error("Missing export entry " + quote(compound_name(theory, name)))
        case Some(entry) => entry
      }

    def theory(theory: String, other_cache: Option[Term.Cache] = None): Theory_Context =
      new Theory_Context(session_context, theory, other_cache)

    def get_source_file(name: String): Option[Store.Source_File] = {
      val store = database_context.store
      (for {
        database <- db_hierarchy.iterator
        file <- store.read_sources(database.db, database.session, name = name).iterator
      } yield file).nextOption()
    }

    def source_file(name: String): Store.Source_File =
      get_source_file(name).getOrElse(error("Missing session source file " + quote(name)))

    def theory_source(theory: String, unicode_symbols: Boolean = false): String = {
      def snapshot_source: Option[String] =
        for {
          snapshot <- document_snapshot
          text <- snapshot.version.nodes.iterator.collectFirst(
            { case (name, node) if name.theory == theory => node.source })
          if text.nonEmpty
        } yield Symbol.output(unicode_symbols, text)

      def db_source: Option[String] = {
        val theory_context = session_context.theory(theory)
        for {
          name <- theory_context.files0(permissive = true).headOption
          file <- get_source_file(name)
        } yield Symbol.output(unicode_symbols, file.bytes.text)
      }

      snapshot_source orElse db_source getOrElse ""
    }

    def classpath(): List[File.Content] = {
      (for {
        session <- session_stack.iterator
        info <- sessions_structure.get(session).iterator
        if info.export_classpath.nonEmpty
        matcher = make_matcher(info.export_classpath)
        entry_name <- entry_names(session = session).iterator
        if matcher(entry_name)
        entry <- get(entry_name.theory, entry_name.name).iterator
      } yield File.content(entry.entry_name.make_path(), entry.bytes)).toList
    }

    override def toString: String =
      "Export.Session_Context(" + commas_quote(session_stack) + ")"
  }

  class Theory_Context private[Export](
    val session_context: Session_Context,
    val theory: String,
    other_cache: Option[Term.Cache]
  ) {
    def cache: Term.Cache = other_cache getOrElse session_context.cache

    def get(name: String): Option[Entry] = session_context.get(theory, name)
    def apply(name: String, permissive: Boolean = false): Entry =
      session_context.apply(theory, name, permissive = permissive)

    def yxml(name: String): XML.Body =
      get(name) match {
        case Some(entry) => entry.yxml
        case None => Nil
      }

    def document_id(): Option[Long] =
      apply(DOCUMENT_ID, permissive = true).text match {
        case Value.Long(id) => Some(id)
        case _ => None
      }

    def files0(permissive: Boolean = false): List[String] =
      split_lines(apply(FILES, permissive = permissive).text)

    def files(permissive: Boolean = false): Option[(String, List[String])] =
      files0(permissive = permissive) match {
        case Nil => None
        case a :: bs => Some((a, bs))
      }

    override def toString: String = "Export.Theory_Context(" + quote(theory) + ")"
  }


  /* export to file-system */

  def export_files(
    store: Store,
    session_name: String,
    export_dir: Path,
    progress: Progress = new Progress,
    export_prune: Int = 0,
    export_list: Boolean = false,
    export_patterns: List[String] = Nil
  ): Unit = {
    using(store.open_database(session_name)) { db =>
      val entry_names = read_entry_names(db, session_name)

      // list
      if (export_list) {
        for (entry_name <- entry_names) progress.echo(entry_name.compound_name)
      }

      // export
      if (export_patterns.nonEmpty) {
        val matcher = make_matcher(export_patterns)
        for {
          entry_name <- entry_names if matcher(entry_name)
          entry <- entry_name.read(db, store.cache)
        } {
          val path = export_dir + entry_name.make_path(prune = export_prune)
          progress.echo("export " + path + (if (entry.executable) " (executable)" else ""))
          Isabelle_System.make_directory(path.dir)
          val bytes = entry.bytes
          if (!path.is_file || Bytes.read(path) != bytes) Bytes.write(path, bytes)
          File.set_executable(path, flag = entry.executable)
        }
      }
    }
  }


  /* Isabelle tool wrapper */

  val default_export_dir: Path = Path.explode("export")

  val isabelle_tool =
    Isabelle_Tool("export", "retrieve theory exports", Scala_Project.here,
      { args =>
        /* arguments */

        var export_dir = default_export_dir
        var dirs: List[Path] = Nil
        var export_list = false
        var no_build = false
        var options = Options.init()
        var export_prune = 0
        var export_patterns: List[String] = Nil

        val getopts = Getopts("""
Usage: isabelle export [OPTIONS] SESSION

  Options are:
    -O DIR       output directory for exported files (default: """ + default_export_dir + """)
    -d DIR       include session directory
    -l           list exports
    -n           no build of session
    -o OPTION    override Isabelle system OPTION (via NAME=VAL or NAME)
    -p NUM       prune path of exported files by NUM elements
    -x PATTERN   extract files matching pattern (e.g. "*:**" for all)

  List or export theory exports for SESSION: named blobs produced by
  isabelle build. Option -l or -x is required; option -x may be repeated.

  The PATTERN language resembles glob patterns in the shell, with ? and *
  (both excluding ":" and "/"), ** (excluding ":"), and [abc] or [^abc],
  and variants {pattern1,pattern2,pattern3}.
""",
          "O:" -> (arg => export_dir = Path.explode(arg)),
          "d:" -> (arg => dirs = dirs ::: List(Path.explode(arg))),
          "l" -> (_ => export_list = true),
          "n" -> (_ => no_build = true),
          "o:" -> (arg => options = options + arg),
          "p:" -> (arg => export_prune = Value.Int.parse(arg)),
          "x:" -> (arg => export_patterns ::= arg))

        val more_args = getopts(args)
        val session_name =
          more_args match {
            case List(session_name) if export_list || export_patterns.nonEmpty => session_name
            case _ => getopts.usage()
          }

        val progress = new Console_Progress()


        /* build */

        if (!no_build) {
          val rc =
            progress.interrupt_handler {
              Build.build_logic(options, session_name, progress = progress, dirs = dirs)
            }
          if (rc != Process_Result.RC.ok) sys.exit(rc)
        }


        /* export files */

        val store = Store(options)
        export_files(store, session_name, export_dir, progress = progress, export_prune = export_prune,
          export_list = export_list, export_patterns = export_patterns)
      })
}
