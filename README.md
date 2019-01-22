# SQLite3 with ICU and extension support for Android

This project is copied and modified from [SQLite Android Bindings](http://www.sqlite.org/android/zip/SQLite+Android+Bindings.zip?uuid=trunk) to support **extension loading**, **full-text searches**  and **multi-language words segmentation**. Please read the [SQLite Android Bindings Documentation](https://sqlite.org/android/doc/trunk/www/index.wiki) for more information.

The following details you should be aware before using it:

* This project uses SQLite3 with `version 3.17.0`.
* The currently supported architectures are `armeabi-v7a` and `arm64-v8a`.
* There are security risks if extension loading is enabled according to [this topic](https://www.sqlite.org/c3ref/enable_load_extension.html), be careful about it.

## Command-line interface

This project provides tools run in command-line, current support `Unix-like OS` only, run the following commands to buid:

```sh
$ cd /<your-project-dir>/host
$ chmod +x build.sh
$ ./build.sh
```

Now you'll find an executable file named `sqlite3` and 3 extension libraries in the directory `./out`. Run the following commands in your command-line to check if it works:

```sql
$ cd out
$ ./sqlite3
SQLite version 3.17.0 2017-02-13 16:02:40
Enter ".help" for usage hints.
Connected to a transient in-memory database.
Use ".open FILENAME" to reopen on a persistent database.
sqlite> SELECT sqlite_compileoption_used('ENABLE_LOAD_EXTENSION');
1
sqlite> SELECT load_extension('./libspellfix');

sqlite> CREATE VIRTUAL TABLE spellfix USING spellfix1;
sqlite> INSERT INTO spellfix(word) VALUES('frustrate');
sqlite> INSERT INTO spellfix(word) VALUES('Frustration');
sqlite> SELECT word FROM spellfix WHERE word MATCH 'frus';
frustrate
Frustration
```

Check the file `build.sh` to find out the compile options, there are much more you may want to know, please read this topic: [How To Compile SQLite.](https://www.sqlite.org/howtocompile.html)

## Build native libraries

All of the first, please make sure you have `NDK` installed, then add the following code into your `local.properties` file to build the libraries:

```
ndk.dir=/your/ndk/directory
```

## Application programming

Load the native library:

```java
System.loadLibrary("sqliteX");
```

Replace the `android.database.sqlite` namespace with `org.sqlite.database.sqlite`. For example, the following:

```java
import android.database.sqlite.SQLiteDatabase;
```

should be replaced with:

```java
import org.sqlite.database.sqlite.SQLiteDatabase;
```

For more details, please read [this topic](https://sqlite.org/android/doc/trunk/www/usage.wiki).

## FTS3, FTS4 and ICU support

> FTS3 and FTS4 are SQLite virtual table modules that allows users to perform full-text searches on a set of documents.

We use `FTS3` and `FTS4` to perform full-text searches, and `icu` to perform `multi-language words segmentation` in SQLite. 

The following code shows how to use `FTS` and `ICU`.

```java
SQLiteDatabase db = helper.getWritableDatabase();
// Create an FTS table with a single column - "content"
// that uses the "icu" tokenizer
db.execSQL("CREATE VIRTUAL TABLE icu_fts USING fts4(tokenize=icu)");
// Insert texts into the table created before
db.execSQL("INSERT INTO icu_fts VALUES('Welcome to China.')");
db.execSQL("INSERT INTO icu_fts VALUES('Welcome to Beijing.')");
db.execSQL("INSERT INTO icu_fts VALUES('中国欢迎你！')");
db.execSQL("INSERT INTO icu_fts VALUES('北京欢迎你！')");
// Perform full-text searches
Cursor c = db.rawQuery("SELECT * FROM icu_fts WHERE icu_fts MATCH 'welcome'", null);
while (c.moveToNext()) {
    Log.d(TAG, "search for 'welcome': " + c.getString(0));
    // Should be: 
    // Welcome to China.
    // Welcome to Beijing.
}
c.close();
c = db.rawQuery("SELECT * FROM icu_fts WHERE icu_fts MATCH '欢迎'", null);
while (c.moveToNext()) {
    Log.d(TAG, "search for '欢迎': " + c.getString(0));
    // Should be:
    // 中国欢迎你！
    // 北京欢迎你！
}
c.close();
```

You can use the `binary operators` to perform logic searches and combine the auxiliary functions to perform more complicated searches. For more details, please read [the documentation](https://www.sqlite.org/fts3.html).

## Extension loading

> SQLite has the ability to load extensions (including new application-defined SQL functions, collating sequences, virtual tables, and VFSes) at run-time. This feature allows the code for extensions to be developed and tested separately from the application and then loaded on an as-needed basis.

Basically, a SQLite extension is a "plugin" that implemented a set of specific functions and can be loaded into SQLite dynamically.

The following code shows how to check if extension loading is supported:

```java
SQLiteDatabase db = helper.getWritableDatabase();
Cursor c = db.rawQuery("SELECT sqlite_compileoption_used('ENABLE_LOAD_EXTENSION')", null);
// The result must not be 0
assert(c.getInt(0) != 0);
```

Enable or disable extension loading:

```java
// The following code CAN NOT run in a transaction

// Enable extension loading
db.enableLoadExtension(true);
// Disable extension loading
db.enableLoadExtension(false);
```

After enabled, you could load your extensions now, take `spellfix` as an example:

```java
// Load successfully if there are no exceptions thrown
Cursor c = db.rawQuery("SELECT load_extension('libspellfix')", null);
c.moveToFirst();
Log.i(TAG, "Load spellfix, result = " + c.getInt(0));
```

Writing your own extensions is also simple, be sure you have read [this topic](https://www.sqlite.org/loadext.html).

## Builtin extensions

There are 3 builtin extensions, `offsets_rank`, `okapi_bm25` and `spellfix`, the source code is placed in the directory `builtin_extensions`. These extensions are enabled by default, you can disable it by adding the following code into your `local.properties` file.

```
useBuiltinExtensions=false
```

### The spellfix1 virtual table

[The documentation](https://www.sqlite.org/spellfix1.html) said:

> This spellfix1 virtual table can be used to search a large vocabulary for close matches. For example, spellfix1 can be used to suggest corrections to misspelled words. Or, it could be used with FTS4 to do full-text search using potentially misspelled words.

You can download the latest source code from [here](https://www.sqlite.org/src/finfo?name=ext/misc/spellfix.c).

A quick look:

```sql
sqlite> SELECT load_extension('./libspellfix');

sqlite> CREATE VIRTUAL TABLE demo USING spellfix1;
sqlite> INSERT INTO demo(word, rank) VALUES('frustrate', 2);
sqlite> INSERT INTO demo(word, rank) VALUES('Frustration', 3);
sqlite> INSERT INTO demo(word, rank) VALUES('frustate', 1);
sqlite> SELECT word FROM demo WHERE word MATCH 'fru*';
frustrate
Frustration
frustate
```

More details can be found at [here](https://www.sqlite.org/spellfix1.html).

### offsets_rank

An extension to use with the function [offsets()](https://www.sqlite.org/fts3.html#the_offsets_function) to calculate simple relevancy of an FTS match. The value returned is the relevancy score (a real value greater than or equal to zero). A larger value indicates a more relevant document.

According to the value returned by the function `offsets()`, it contains 4 integer value on each term, the last value is the size of the matching term in bytes, typically the value will keep the same with the given term, but in some cases, for example, when create an fts table with option tokenize=porter, and contains the following records:

```
docid   content
------  -------
1       sleep
2       sleeping
```

when we execute the queries:

```sql
SELECT docid, content, offsets(fts) FROM fts WHERE fts MATCH 'sleeping';
SELECT docid, content, offsets(fts) FROM fts WHERE fts MATCH 'sleep';
```

will get the exact same results:

```
docid   content   offsets
------  -------   -------
1       sleep     0 0 0 5
2       sleeping  0 0 0 8
```

but we want a higher score on record `sleeping` when searches for `sleeping`, the function `offsets_rank` will parse the value returned by the function `offsets` and adjust the relevancy score. The following query returns the documents that match the full-text query sorted from most to least relevant:

```sql
SELECT docid, content FROM fts WHERE fts MATCH 'sleeping'
    ORDER BY offsets_rank(offsets(fts)) DESC;
```

the results will be:

```
docid  content
------ --------
2      sleeping
1      sleep
```

### okapi_bm25

This file is a fork from [sqlite-okapi-bm25](https://github.com/neozenith/sqlite-okapi-bm25), that is under the [MIT License](https://opensource.org/licenses/MIT). The ranking function uses the built-in [matchinfo](https://www.sqlite.org/fts3.html#matchinfo) function to obtain the data necessary to calculate the scores. Make sure you have read these documentations before use.

## License

Except the files included in [SQLite](https://www.sqlite.org/copyright.html), all other files are under the [MIT License](https://opensource.org/licenses/MIT).
