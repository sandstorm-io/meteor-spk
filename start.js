// Copyright (c) 2014 Sandstorm Development Group, Inc. and contributors
// Licensed under the MIT License:
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

// Application start script. This launches Mongo, then delegates to main.js.
// meteor-spk will automatically include this in your package; you don't need
// to worry about it.

var child_process = require("child_process");
var fs = require("fs");

var dbPath = "/var/wiredTigerDb"

function runChildProcess(child, name, continuation) {
  child.on("error", function (err) {
    console.error("error in " + name + ": "  + err.stack);
    process.exit(1);
  });

  child.on("exit", function (code, signal) {
    if (signal) {
      console.error(name + " failed with signal: " + signal);
      process.exit(1);
    }
    if (code !== 0) {
      console.error(name + " exited with error code: " + code);
      process.exit(1);
    }
    continuation();
  });
}

function startMongo(continuation) {
  console.log("** Starting Mongo...");
  var db = child_process.spawn("/bin/mongod",
                               [ "--fork", "--port", "4002", "--dbpath", dbPath,
                                 "--noauth", "--bind_ip", "127.0.0.1", "--nohttpinterface",
                                 "--storageEngine", "wiredTiger",
                                 "--wiredTigerEngineConfigString", "log=(prealloc=false,file_max=200KB)",
                                 "--wiredTigerCacheSizeGB", "1",
                                 "--logpath", dbPath + "/mongo.log" ],
                               { stdio: "inherit" });

  runChildProcess(db, "Mongo", continuation);
}

function runApp() {
  console.log("** Starting Meteor...");
  process.env.MONGO_URL="mongodb://127.0.0.1:4002/meteor";
  process.env.ROOT_URL="http://127.0.0.1:4000";
  process.env.PORT="4000";
  require("./main.js");
}

var migrationDumpPath = "/var/migrationMongoDump";

if (fs.existsSync(dbPath) && !fs.existsSync(migrationDumpPath)) {
  startMongo(runApp);
} else {
  // The old database was in /var.
  if (!fs.existsSync("/var/journal")) {
    // No migration required.
    fs.mkdirSync(dbPath);
    startMongo(runApp);
  } else {
    console.log("Starting migration to WiredTiger storage engine...");

    if (fs.existsSync(migrationDumpPath)) {
      console.log("It looks like a previous attempt to migrate failed. Cleaning it up...");
      var now = (new Date()).getTime();
      if (fs.existsSync(dbPath)) {
        fs.rename(dbPath, "/var/failedMigration" + now);
      }
      fs.rename(migrationDumpPath, "/var/failedMigrationDump" + now);
    }

    console.log("launching niscd");
    var oldDb = child_process.spawn("/bin/niscud", [ "--port", "4002", "--dbpath", "/var",
                                                     "--noauth", "--bind_ip", "127.0.0.1",
                                                     "--nohttpinterface", "--noprealloc",
                                                     "--logpath", "/var/mongo.log" ], {
                                                       stdio: "inherit"
                                                     });
    // TODO: We ought to wait for "waiting for connections" on stdout.
    runChildProcess(oldDb, "nisucd", function () {});

    var dump = child_process.spawn("/bin/mongodump",
                                   ["--host", "127.0.0.1:4002",
                                    "--out", migrationDumpPath]);

    runChildProcess(dump, "mongodump", function() {
      oldDb.kill();
      fs.mkdirSync(dbPath);
      startMongo(function () {
        var restore = child_process.spawn("/bin/mongorestore",
                                          ["--host", "127.0.0.1:4002",
                                           migrationDumpPath]);

        runChildProcess(restore, "mongorestore", function () {
          fs.rename(migrationDumpPath, "/var/successfulMigrationDump");
          runApp();
        });
      });
    });
  }
}

